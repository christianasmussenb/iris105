# IRIS105 Wiki

## 📚 Documentación

### Inicio Rápido
- [**Home**](Home)
- [**Getting Started**](Getting-Started)

### Arquitectura y Diseño
- [**Architecture**](Architecture)
- [**API Reference**](API-Reference)
- [**ML Model**](ML-Model)

### Desarrollo
- [**Development Guide**](Development-Guide)

### Soporte
- [**Troubleshooting**](Troubleshooting)
- [**FAQ**](FAQ)

---

## 🔗 Enlaces Rápidos

- [GitHub Repo](https://github.com/christianasmussenb/iris105)
- [OpenAPI Spec](../docs/openapi.yaml)
- [InterSystems Docs](https://docs.intersystems.com/)
- [Developer Community](https://community.intersystems.com/)

---

## 🚀 Quick Commands

```bash
# Health check
curl http://localhost:52773/csp/mltest/api/health
```

```objectscript
# Compile
Do $system.OBJ.CompilePackage("IRIS105","ckr")
```

```sql
# Train model
TRAIN MODEL NoShowModel2;
```
