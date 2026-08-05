document.querySelector('.form-row form').addEventListener('submit', function (e) {
  const checks = document.querySelectorAll('.options-row input[type=checkbox]');
  const any = Array.from(checks).some(c => c.checked);
  if (!any) {
    e.preventDefault();
    alert('Select at least one category');
  }
});