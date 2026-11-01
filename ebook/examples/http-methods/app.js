const result = document.querySelector('#result');

const examples = {
  GET: { url: 'api.php?tema=red&nivel=basico' },
  POST: {
    url: 'api.php',
    options: {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({ nombre: 'Ada', curso: 'Web' }),
    },
  },
  PUT: {
    url: 'api.php',
    options: {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: 42, nombre: 'Libro' }),
    },
  },
  PATCH: {
    url: 'api.php',
    options: {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: 42, precio: 19.9 }),
    },
  },
  DELETE: { url: 'api.php?id=42', options: { method: 'DELETE' } },
};

async function send(method) {
  const example = examples[method];
  result.textContent = `Enviando ${method}…`;
  try {
    const response = await fetch(example.url, example.options);
    const body = await response.json();
    result.textContent = `${response.status} ${response.statusText}\n${JSON.stringify(body, null, 2)}`;
  } catch (error) {
    result.textContent = `No se pudo completar la petición: ${error.message}`;
  }
}

document.querySelectorAll('button[data-method]').forEach((button) => {
  button.addEventListener('click', () => send(button.dataset.method));
});
