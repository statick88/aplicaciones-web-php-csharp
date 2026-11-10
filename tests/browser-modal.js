async (page) => {
  await page.goto("http://127.0.0.1:4188/chapters/01-web-foundations.html", { waitUntil: "networkidle" });
  const trigger = page.getByRole("button", { name: "Abrir diálogo de ejemplo" });
  const dialog = page.getByRole("dialog", { name: "Diálogo de ejemplo" });
  const assert = (ok, message) => { if (!ok) throw new Error(message); };
  await trigger.click();
  assert(await dialog.isVisible(), "El diálogo no se abrió");
  assert(await dialog.evaluate((node) => node.contains(document.activeElement)), "El diálogo no recibió el foco");
  await page.getByRole("button", { name: "Cerrar diálogo", exact: true }).focus();
  await page.keyboard.press("Shift+Tab");
  assert(await dialog.evaluate((node) => node.contains(document.activeElement)), "El foco salió del diálogo");
  await page.keyboard.press("Escape");
  assert(!(await dialog.isVisible()), "Escape no cerró el diálogo");
  assert(await trigger.evaluate((node) => node === document.activeElement), "El foco no volvió al botón");
  await trigger.click();
  await page.getByRole("button", { name: "Entendido", exact: true }).click();
  assert(!(await dialog.isVisible()), "El botón no cerró el diálogo");
  return { opens: true, keyboardFocus: true, escape: true, closes: true };
}
