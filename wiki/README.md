# IRIS105 Wiki Content

Este directorio contiene todo el contenido para el wiki de GitHub del proyecto IRIS105.

## 📋 Páginas del Wiki

| Archivo | Descripción |
|---------|-------------|
| `Home.md` | Página principal del wiki |
| `Getting-Started.md` | Guía de instalación y configuración rápida |
| `Architecture.md` | Arquitectura detallada del sistema |
| `API-Reference.md` | Documentación completa de la API REST |
| `ML-Model.md` | Guía de IntegratedML y el modelo NoShowModel2 |
| `Development-Guide.md` | Guía de desarrollo y buenas prácticas |
| `Troubleshooting.md` | Solución de problemas comunes |
| `FAQ.md` | Preguntas frecuentes |
| `_Sidebar.md` | Barra lateral de navegación |

## 🚀 Cómo Publicar en GitHub Wiki

### Opción 1: Clonar el Wiki y Copiar Archivos

```bash
# 1. Clonar el repositorio wiki (separado del repo principal)
git clone https://github.com/christianasmussenb/iris105.wiki.git

# 2. Copiar archivos desde wiki/ al repo clonado
cd iris105.wiki
cp ../iris105/wiki/*.md .

# 3. Commit y push
git add .
git commit -m "Update wiki documentation"
git push origin master
```

### Opción 2: Editar Manualmente en GitHub

1. Ir a la pestaña **Wiki** en GitHub: https://github.com/christianasmussenb/iris105/wiki
2. Para cada archivo `.md` en este directorio:
   - Crear o editar la página correspondiente
   - Copiar el contenido del archivo
   - Guardar

### Opción 3: Usar la Interfaz Web de GitHub

1. Habilitar el wiki en **Settings** → **Features** → **Wikis**
2. Ir a la pestaña **Wiki**
3. Crear páginas manualmente copiando el contenido de cada archivo `.md`

## 📝 Estructura del Wiki

El wiki está organizado de la siguiente manera:

```
Home (página principal)
├── Getting Started (configuración inicial)
├── Architecture (diseño del sistema)
│   └── API Reference (documentación de endpoints)
│   └── ML Model (uso de IntegratedML)
├── Development Guide (desarrollo)
└── Support
    ├── Troubleshooting (problemas comunes)
    └── FAQ (preguntas frecuentes)
```

## ✏️ Mantenimiento

### Actualizar el Wiki

Cuando hagas cambios en el proyecto:

1. **Actualizar archivos locales**: Edita los archivos `.md` en `wiki/`
2. **Commit en el repo principal**: 
   ```bash
   git add wiki/
   git commit -m "Update wiki documentation"
   git push
   ```
3. **Publicar en GitHub Wiki**: Usa una de las opciones anteriores

### Mantener Sincronizado

El contenido en `wiki/` del repo principal es la fuente de verdad. El wiki de GitHub es una copia para visualización.

## 🔗 Enlaces en el Wiki

Los enlaces entre páginas del wiki usan sintaxis de GitHub Wiki:

```markdown
[Link a otra página](Nombre-De-Pagina)
[Link a Getting Started](Getting-Started)
```

NO uses `.md` en los enlaces del wiki.

## 📸 Imágenes

Para incluir imágenes en el wiki:

1. Subir imagen al repo en `docs/images/`
2. En el wiki, referenciar con URL absoluta:
   ```markdown
   ![Alt text](https://raw.githubusercontent.com/christianasmussenb/iris105/main/docs/images/diagram.png)
   ```

## 🎨 Formato

El wiki usa **GitHub Flavored Markdown** con soporte para:

- ✅ Tablas
- ✅ Syntax highlighting
- ✅ Task lists
- ✅ Emojis
- ✅ Alerts (Note, Warning, etc.)

## 📋 Checklist de Publicación

Antes de publicar, verificar:

- [ ] Todos los archivos `.md` tienen contenido completo
- [ ] Los enlaces entre páginas funcionan
- [ ] El código de ejemplo es correcto
- [ ] La navegación en `_Sidebar.md` está completa
- [ ] No hay información sensible (contraseñas, tokens reales)
- [ ] Las URLs y endpoints son correctos

## 🆘 Ayuda

Si tienes problemas publicando el wiki:

1. **Wiki no visible**: Habilitar en Settings → Features → Wikis
2. **Sin permisos para editar**: Verificar permisos de colaborador
3. **Enlaces rotos**: Verificar sintaxis sin `.md`
4. **Formato incorrecto**: Validar markdown con herramienta online

## 📚 Recursos

- [GitHub Wiki Documentation](https://docs.github.com/en/communities/documenting-your-project-with-wikis)
- [Markdown Guide](https://www.markdownguide.org/)
- [GitHub Flavored Markdown Spec](https://github.github.com/gfm/)

---

**Última actualización**: Enero 2026
