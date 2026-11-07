export function initializeLessonLayout(root = document) {
  const layout = root.querySelector(".lesson-layout");
  const toggle = root.querySelector("[data-topics-toggle]");
  const sidebar = root.querySelector("#lesson-topics");
  if (!layout || !toggle || !sidebar || toggle.dataset.initialized) return;
  toggle.dataset.initialized = "true";

  function render() {
    layout.classList.toggle("topics-hidden", sidebar.hidden);
    toggle.setAttribute("aria-expanded", String(!sidebar.hidden));
    toggle.textContent = sidebar.hidden ? "Mostrar temas" : "Ocultar temas";
  }

  render();
  toggle.hidden = false;
  toggle.addEventListener("click", () => {
    sidebar.hidden = !sidebar.hidden;
    render();
  });
}

initializeLessonLayout();
