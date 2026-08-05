const timer = document.querySelector('[data-timer-running="true"]');
if (timer) {
  setInterval(function () { location.reload(); }, 1000);
}