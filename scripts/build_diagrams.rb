#!/usr/bin/env ruby
# All paths are relative to the repository, not to the caller's working directory.
require 'digest'
require 'fileutils'
require 'json'
require 'rexml/document'
require 'tmpdir'
require 'timeout'
require 'yaml'

class DiagramBuilder
  TOOLS = %w[lualatex dvisvgm pdfinfo].freeze
  attr_reader :root

  def initialize(root = File.expand_path('..', __dir__))
    @root = File.expand_path(root)
  end

  def path(relative)
    File.join(root, relative)
  end

  def sources
    Dir.glob(path('_diagrams/*.tex')).sort.reject { |file| File.basename(file) == 'preamble.tex' }
  end

  def input_digest
    files = sources + [path('_diagrams/preamble.tex'), __FILE__] +
      Dir.glob(path('_diagrams/shared/**/*')).select { |file| File.file?(file) }
    fingerprint(files)
  end

  def source_year(source)
    values = File.read(source).lines.filter_map { |line| line[/^\s*%\s*year:\s*(.*?)\s*$/, 1] }
    unless values.size == 1 && values.first.match?(/\A[1-9]\d{3}\z/)
      raise "Diagram #{File.basename(source)}: provide exactly one % year: YYYY comment"
    end
    values.first.to_i
  end

  def fingerprint(files)
    Digest::SHA256.hexdigest(files.sort.map { |file| [file.delete_prefix(root), File.binread(file)] }.flatten.join("\0"))
  end

  def run_command(command, directory, timeout: 120)
    log = File.join(directory, 'command.log')
    tex_cache = path('.cache/diagrams/texmf')
    FileUtils.mkdir_p(tex_cache)
    environment = { 'LC_ALL' => 'C', 'TEXMFVAR' => tex_cache, 'TEXMFCACHE' => tex_cache }
    pid = Process.spawn(environment, *command, chdir: directory, out: log, err: [:child, :out], pgroup: true)
    begin
      status = Timeout.timeout(timeout) { Process.wait2(pid).last }
    rescue Timeout::Error
      Process.kill('KILL', -pid) rescue nil
      Process.wait(pid) rescue nil
      raise "#{command.first} timed out after #{timeout}s\n#{File.read(log)}"
    end
    output = File.read(log)
    raise "#{command.first} failed\n#{output}" unless status.success?
    output
  rescue Errno::ENOENT
    raise "Missing tool #{command.first}; see DEVELOPMENT.md for diagram dependencies."
  end

  def svg_dimensions(file)
    svg = REXML::Document.new(File.read(file)).root
    raise 'Expected an SVG root' unless svg&.name == 'svg'
    box = svg.attributes['viewBox'].to_s.split(/[\s,]+/).map { |value| Float(value) }
    raise 'SVG must have a positive, finite viewBox' unless box.size == 4 && box.all?(&:finite?) && box[2].positive? && box[3].positive?
    [box[2], box[3]]
  end

  def compile(source, target, work)
    FileUtils.cp(source, File.join(work, 'diagram.tex'))
    FileUtils.cp(path('_diagrams/preamble.tex'), File.join(work, 'preamble.tex'))
    FileUtils.cp_r(path('_diagrams/shared'), File.join(work, 'shared')) if Dir.exist?(path('_diagrams/shared'))
    File.write(File.join(work, 'wrapper.tex'), <<~'TEX')
      \documentclass[tikz,border=2pt]{standalone}
      \input{preamble.tex}
      \begin{document}
      \input{diagram.tex}
      \end{document}
    TEX
    2.times { run_command(%w[lualatex --no-shell-escape --interaction=nonstopmode --halt-on-error --file-line-error wrapper.tex], work) }
    info = run_command(%w[pdfinfo wrapper.pdf], work)
    raise 'Each diagram must produce exactly one PDF page' unless info.match?(/^Pages:\s+1\s*$/)
    run_command(['dvisvgm', '--pdf', '--no-fonts', '--output=diagram.svg', 'wrapper.pdf'], work)
    dimensions = svg_dimensions(File.join(work, 'diagram.svg'))
    FileUtils.cp(File.join(work, 'diagram.svg'), target)
    dimensions
  end

  def write_if_changed(file, content)
    return if File.file?(file) && File.binread(file) == content
    FileUtils.mkdir_p(File.dirname(file))
    temporary = "#{file}.tmp"
    File.binwrite(temporary, content)
    File.rename(temporary, file)
  end

  def build
    FileUtils.mkdir_p(path('.cache/diagrams'))
    File.open(path('.cache/diagrams/build.lock'), 'w') do |lock|
      lock.flock(File::LOCK_EX)
      build_locked
    rescue StandardError
      # A watching Jekyll must not continue advertising stale diagrams on failure.
      FileUtils.rm_f(path('_data/diagrams.yml'))
      raise
    end
  end

  def build_locked
    entries = []
    Dir.mktmpdir('tikz-build-') do |stage|
      versions = sources.empty? ? '' : TOOLS.map do |tool|
        run_command([tool, tool == 'pdfinfo' ? '-v' : '--version'], stage)
      end.join("\n")
      shared = [path('_diagrams/preamble.tex'), __FILE__] +
        Dir.glob(path('_diagrams/shared/**/*')).select { |file| File.file?(file) }
      sources.each do |source|
        id = File.basename(source, '.tex')
        year = source_year(source)
        raise "Invalid diagram filename: #{id}; use lowercase letters, numbers, and hyphens" unless id.match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)
        key = Digest::SHA256.hexdigest(fingerprint(shared + [source]) + versions)
        cached = path(".cache/diagrams/#{key}.svg")
        dimensions = nil
        begin
          dimensions = svg_dimensions(cached) if File.file?(cached)
        rescue StandardError
          dimensions = nil
        end
        if dimensions
          puts "Diagram #{id}: cached"
        else
          Dir.mktmpdir('compile-', stage) do |work|
            begin
              dimensions = compile(source, cached, work)
            rescue StandardError => error
              latex_log = File.join(work, 'wrapper.log')
              raise "Diagram #{id} (#{source}): #{error.message}\n#{File.read(latex_log) if File.file?(latex_log)}"
            end
          end
          puts "Diagram #{id}: compiled"
        end
        FileUtils.cp(cached, File.join(stage, "#{id}.svg"))
        entries << { 'id' => id, 'year' => year, 'url' => "/assets/diagrams/#{id}.svg", 'width' => dimensions[0], 'height' => dimensions[1] }
      end
      # Do not change public output until every source has compiled successfully.
      FileUtils.mkdir_p(path('assets/diagrams'))
      entries.each { |entry| write_if_changed(path("assets/diagrams/#{entry['id']}.svg"), File.binread(File.join(stage, "#{entry['id']}.svg"))) }
      expected = entries.map { |entry| path("assets/diagrams/#{entry['id']}.svg") }
      (Dir.glob(path('assets/diagrams/*.svg')) - expected).each { |file| FileUtils.rm_f(file) }
      write_if_changed(path('_data/diagrams.yml'), YAML.dump(entries))
    end
    puts "Diagrams ready: #{entries.length}"
    entries
  end

  def watch
    previous = nil
    loop do
      current = input_digest
      if current != previous
        previous = current
        begin
          build
        rescue StandardError => error
          warn error.message
        end
      end
      sleep 1
    end
  rescue Interrupt
    puts 'Diagram watcher stopped.'
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    builder = DiagramBuilder.new
    ARGV.include?('--watch') ? builder.watch : builder.build
  rescue StandardError => error
    warn error.message
    exit 1
  end
end
