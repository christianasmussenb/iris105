# Guía de Publicación del Wiki IRIS105

## ✅ Wiki Completado

Se ha creado un wiki completo con **10 páginas** y más de **3,700 líneas** de documentación.

## 📚 Contenido del Wiki

### Páginas Principales

1. **Home.md** (Página Principal)
   - Descripción del proyecto
   - Características principales
   - Links a toda la documentación
   - Estado del proyecto

2. **Getting-Started.md** (Inicio Rápido)
   - Requisitos previos
   - 8 pasos de instalación
   - Verificación de la instalación
   - Troubleshooting básico

3. **Architecture.md** (Arquitectura)
   - Diagrama de 3 capas
   - Componentes principales
   - Flujos de datos
   - Esquema de base de datos

4. **API-Reference.md** (Referencia API)
   - Documentación completa de 15+ endpoints
   - Ejemplos de request/response
   - Códigos de error
   - Autenticación

5. **ML-Model.md** (Modelo de ML)
   - Guía de IntegratedML
   - Entrenamiento del modelo
   - Scoring y predicción
   - Re-entrenamiento

6. **Development-Guide.md** (Guía de Desarrollo)
   - Configuración del entorno
   - Convenciones de código
   - Cómo añadir funcionalidades
   - Testing

7. **Troubleshooting.md** (Solución de Problemas)
   - Problemas comunes y soluciones
   - Debugging tips
   - Comandos de diagnóstico

8. **FAQ.md** (Preguntas Frecuentes)
   - 40+ preguntas respondidas
   - Categorías: General, ML, Seguridad, Datos, API, etc.

9. **_Sidebar.md** (Navegación)
   - Menú lateral del wiki
   - Links rápidos
   - Comandos útiles

10. **README.md** (Instrucciones)
    - Cómo publicar el wiki en GitHub
    - Mantenimiento
    - Checklist de publicación

## 🚀 Opciones para Publicar en GitHub

### Opción 1: GitHub Web UI (Más Fácil) ⭐ Recomendado

1. Ve a: https://github.com/christianasmussenb/iris105
2. Click en la pestaña **Wiki**
3. Si el wiki no está habilitado:
   - Ve a **Settings** → **Features**
   - Marca **Wikis**
4. Click en **Create the first page**
5. Para cada archivo en `wiki/`:
   - Copia el contenido del archivo
   - Crea una página nueva en el wiki
   - Pega el contenido
   - Guarda

**Orden sugerido de creación**:
1. Home
2. Getting-Started
3. Architecture
4. API-Reference
5. ML-Model
6. Development-Guide
7. Troubleshooting
8. FAQ
9. _Sidebar (especial - crea la navegación lateral)

### Opción 2: Git Clone del Wiki

```bash
# 1. Clonar el repositorio wiki (es un repo separado)
git clone https://github.com/christianasmussenb/iris105.wiki.git

# 2. Copiar archivos
cd iris105.wiki
cp ../iris105/wiki/*.md .

# 3. Commit y push
git add .
git commit -m "Documentación completa del wiki IRIS105"
git push origin master
```

### Opción 3: Script Automatizado

```bash
#!/bin/bash
# publish-wiki.sh

REPO="christianasmussenb/iris105"
WIKI_REPO="$REPO.wiki"

# Clonar wiki
git clone "https://github.com/$WIKI_REPO.git" /tmp/iris105-wiki

# Copiar archivos
cp wiki/*.md /tmp/iris105-wiki/

# Push
cd /tmp/iris105-wiki
git add .
git commit -m "Update wiki documentation"
git push origin master

# Cleanup
cd -
rm -rf /tmp/iris105-wiki

echo "Wiki publicado exitosamente!"
```

## 📋 Checklist de Publicación

Antes de publicar, verifica:

- [x] ✅ Todos los archivos .md están creados
- [x] ✅ El contenido es completo y preciso
- [x] ✅ Los ejemplos de código funcionan
- [x] ✅ Los enlaces internos usan sintaxis correcta
- [x] ✅ No hay información sensible
- [ ] ⏳ Wiki habilitado en GitHub Settings
- [ ] ⏳ Páginas publicadas en el wiki de GitHub
- [ ] ⏳ Navegación _Sidebar funciona
- [ ] ⏳ Enlaces entre páginas verificados

## 🎯 Estructura de Navegación

```
Home (Página Principal)
│
├── Getting Started
│   └── Requisitos, Instalación, Verificación
│
├── Architecture
│   ├── Vista General (3 capas)
│   ├── Componentes
│   └── Flujos de Datos
│
├── API Reference
│   ├── Health Check
│   ├── Scoring
│   ├── Estadísticas
│   ├── Analytics
│   └── Configuración
│
├── ML Model
│   ├── Introducción a IntegratedML
│   ├── Entrenamiento
│   ├── Scoring
│   └── Re-entrenamiento
│
├── Development Guide
│   ├── Setup de Entorno
│   ├── Compilación
│   ├── Convenciones
│   ├── Añadir Funcionalidades
│   └── Testing
│
├── Troubleshooting
│   ├── Instalación
│   ├── Web Apps
│   ├── Machine Learning
│   ├── API REST
│   └── Performance
│
└── FAQ
    ├── General
    ├── Arquitectura
    ├── Machine Learning
    ├── Seguridad
    ├── Datos
    ├── API REST
    └── Deployment
```

## 🔗 Enlaces Importantes

Una vez publicado, el wiki estará disponible en:
```
https://github.com/christianasmussenb/iris105/wiki
```

Páginas individuales:
```
https://github.com/christianasmussenb/iris105/wiki/Home
https://github.com/christianasmussenb/iris105/wiki/Getting-Started
https://github.com/christianasmussenb/iris105/wiki/API-Reference
etc.
```

## 📝 Mantenimiento del Wiki

### Actualizar Contenido

1. **Editar archivos locales**: Modifica los archivos en `wiki/`
2. **Commit en el repo**: 
   ```bash
   git add wiki/
   git commit -m "Update wiki: [descripción]"
   git push
   ```
3. **Actualizar en GitHub Wiki**: Usar Opción 1 o 2 para republicar

### Sincronización

El directorio `wiki/` en el repo principal es la **fuente de verdad**.
El wiki de GitHub es una **copia para visualización**.

Mantén ambos sincronizados:
- Cambios en archivos locales → Commit → Republicar en wiki
- NO edites directamente en el wiki de GitHub (se perderán cambios)

## 💡 Tips

### Enlaces en el Wiki

En el wiki de GitHub, usa:
```markdown
[Link a otra página](Nombre-De-Pagina)
```

NO uses `.md` en los enlaces:
```markdown
❌ [Link](Getting-Started.md)  # NO
✅ [Link](Getting-Started)      # SÍ
```

### Imágenes

Para añadir imágenes:
1. Guardar en `docs/images/`
2. Commit en el repo
3. En el wiki, usar URL absoluta:
```markdown
![Alt](https://raw.githubusercontent.com/christianasmussenb/iris105/main/docs/images/diagram.png)
```

### Código

El wiki soporta syntax highlighting:
```objectscript
ClassMethod Example() As %Status
{
  Return $$$OK
}
```

```sql
SELECT * FROM IRIS105_Domain.Appointment;
```

```bash
curl http://localhost:52773/csp/mltest/api/health
```

## ✅ Resultado Final

Una vez publicado, tendrás un wiki profesional con:

- ✅ **Documentación completa** para usuarios y desarrolladores
- ✅ **Guías paso a paso** para setup, desarrollo y ML
- ✅ **Referencia completa de API** con ejemplos
- ✅ **Troubleshooting** para problemas comunes
- ✅ **FAQ** con respuestas a 40+ preguntas
- ✅ **Navegación fácil** con sidebar
- ✅ **3,700+ líneas** de documentación de calidad

## 🎉 ¡Siguiente Paso!

**Publica el wiki ahora usando una de las 3 opciones descritas arriba.**

Recomendación: Empieza con **Opción 1 (Web UI)** si es tu primera vez.

---

**¿Necesitas ayuda?**

- Ver `wiki/README.md` para detalles técnicos
- [GitHub Wiki Docs](https://docs.github.com/en/communities/documenting-your-project-with-wikis)
- Abrir un issue en el repositorio
