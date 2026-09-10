(() => {
  if (!navigator.clipboard?.writeText) return;

  document.querySelectorAll('[data-copy-email]').forEach((button) => {
    const email = document.getElementById(button.dataset.copyEmail);
    const status = document.getElementById(button.dataset.copyStatus);
    if (!email || !status) return;

    button.hidden = false;
    button.addEventListener('click', async () => {
      try {
        await navigator.clipboard.writeText(email.textContent.trim());
        status.textContent = 'Email address copied.';
      } catch {
        status.textContent = 'Please select and copy the email address above.';
      }
    });
  });
})();
