require_relative '../scripts/build_diagrams'

def assert(value, message)
  raise message unless value
end

def expect_failure(fragment)
  begin
    yield
  rescue StandardError => error
    assert(error.message.include?(fragment), "Expected #{fragment}, got #{error.message}")
    return
  end
  raise "Expected failure containing #{fragment}"
end

Dir.mktmpdir('diagram-tests-') do |root|
  FileUtils.mkdir_p(File.join(root, '_diagrams/shared'))
  preamble = File.join(root, '_diagrams/preamble.tex')
  File.write(preamble, <<~'TEX')
    \usepackage{amsmath,amssymb,tikz}
    \usetikzlibrary{arrows.meta,positioning}
    \input{shared/macros.tex}
  TEX
  File.write(File.join(root, '_diagrams/shared/macros.tex'), '\newcommand{\testlabel}{x^2+\alpha}')
  source = File.join(root, '_diagrams/test-diagram.tex')
  fixture = <<~'TEX'
    % year: 2025
    \begin{tikzpicture}
      \node[draw,blue] (a) {$\testlabel$};
      \node[draw,right=of a] (b) {$\mathbb{F}$};
      \draw[-{Stealth},red] (a) -- (b);
    \end{tikzpicture}
  TEX
  File.write(source, fixture)
  builder = DiagramBuilder.new(root)
  assert(builder.sources == [source], 'Shared files or preamble were discovered as diagrams')
  first = builder.build
  assert(first[0]['year'] == 2025, 'Source year missing from manifest')
  assert(first.size == 1 && first[0]['width'].positive? && first[0]['height'].positive?, 'Invalid manifest')
  output = File.join(root, 'assets/diagrams/test-diagram.svg')
  assert(!File.read(output).match?(/<text\b/), 'Font glyphs should be outlines')
  stamp = File.mtime(output)
  builder.build
  assert(File.mtime(output) == stamp, 'Unchanged public SVG rewritten')
  assert(Dir.glob(File.join(root, '.cache/diagrams/*.svg')).size == 1, 'Cache not reused')

  File.write(source, fixture + "\n% source changed\n")
  builder.build
  assert(Dir.glob(File.join(root, '.cache/diagrams/*.svg')).size == 2, 'Source cache not invalidated')
  File.write(File.join(root, '_diagrams/shared/macros.tex'), '\newcommand{\testlabel}{y^3+\beta}')
  builder.build
  assert(Dir.glob(File.join(root, '.cache/diagrams/*.svg')).size == 3, 'Shared cache not invalidated')

  File.write(source, fixture.sub('% year: 2025', '% year: invalid'))
  expect_failure('test-diagram.tex: provide exactly one % year: YYYY') { builder.build }
  File.write(source, fixture.sub('% year: 2025', ''))
  expect_failure('test-diagram.tex: provide exactly one % year: YYYY') { builder.build }
  File.write(source, fixture.sub('% year: 2025', "% year: 2025\n% year: 2024"))
  expect_failure('test-diagram.tex: provide exactly one % year: YYYY') { builder.build }
  File.write(source, fixture.sub('2025', '2024'))
  assert(builder.build[0]['year'] == 2024, 'Changed year not reflected in manifest')

  File.write(File.join(root, '_diagrams/broken.tex'), "% year: 2025\n" + '\undefinedDiagramCommand')
  expect_failure('Diagram broken') { builder.build }
  assert(!File.exist?(File.join(root, '_data/diagrams.yml')), 'Failed build advertised stale manifest')
  FileUtils.rm_f(File.join(root, '_diagrams/broken.tex'))
  File.write(File.join(root, '_diagrams/multipage.tex'), <<~'TEX')
    % year: 2025
    \begin{tikzpicture}\draw (0,0)--(1,1);\end{tikzpicture}
    \begin{tikzpicture}\draw (0,0)--(2,2);\end{tikzpicture}
  TEX
  expect_failure('exactly one PDF page') { builder.build }
  FileUtils.rm_f(File.join(root, '_diagrams/multipage.tex'))
  builder.build
  FileUtils.rm_f(source)
  assert(builder.build.empty?, 'Deleted source remains in catalogue')
  assert(!File.exist?(output), 'Deleted SVG still published')
  assert(YAML.load_file(File.join(root, '_data/diagrams.yml')) == [], 'Empty catalogue invalid')
  puts 'Diagram integration checks passed: discovery, compilation, cache, shared macros, errors, page count, deletion, empty catalogue.'
end
