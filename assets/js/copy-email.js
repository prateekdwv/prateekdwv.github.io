(() => {
  const button = document.getElementById('copy-email');
  const email = document.getElementById('footer-email');
  const status = document.getElementById('copy-email-status');
  if (!button || !email || !status || !navigator.clipboard?.writeText) return;

  button.hidden = false;
  button.addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(email.textContent.trim());
      status.textContent = 'Email address copied.';
    } catch {
      status.textContent = 'Please select and copy the email address above.';
    }
  });
})();
