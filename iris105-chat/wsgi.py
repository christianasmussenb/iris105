"""
WSGI entry point para IRIS Web Gateway (WSGI Experimental).
Adapta la app FastAPI (ASGI) a WSGI usando a2wsgi.

Configuración en IRIS Management Portal:
  Nombre de aplicación : wsgi
  Nombre invocable     : app
  Directorio           : <path absoluto a iris105-chat/>
"""
from a2wsgi import ASGIMiddleware
from main import app as _asgi_app

app = ASGIMiddleware(_asgi_app)
