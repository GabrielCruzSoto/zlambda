# ZLambda - Kit de Herramientas para Desarrollo Lambda

ZLambda es una herramienta de línea de comandos (CLI) diseñada para facilitar el desarrollo y despliegue de funciones AWS Lambda. Simplifica el ciclo de vida del desarrollo de funciones serverless, desde la preparación del entorno local hasta el despliegue en AWS.

## Características Principales

- 🚀 **Ejecución Local**: Prueba tus funciones Lambda localmente antes de desplegarlas
- 📦 **Gestión de Layers**: Manejo automático de layers de AWS Lambda, incluyendo:
  - Descarga e instalación de layers
  - Soporte para instalación de dependencias vía pip
- 🛠️ **Preparación de Entorno**: Configuración automática de entornos virtuales con Conda
- ☁️ **Despliegue a AWS**: Proceso simplificado de despliegue de funciones a AWS

## Requisitos Previos

- AWS CLI configurado
- Conda instalado
- jq (para procesamiento JSON)
- Python 3.12+

## Estructura del Proyecto

```
zlambda/
├── bash/
│   ├── lib/
│   │   └── commands/
│   │       ├── aws.deploy.command.sh
│   │       ├── local.lambda-prepate-env.command.sh
│   │       ├── local.lambda-run.sh
│   │       └── manager.command.sh
│   └── zlambda
└── config/
    ├── lambda_config.json
    └── lambda_cloudformation.yml
```

## Uso

### Comandos Básicos

```bash
./zlambda -r <runtime> -a <action>
```

Donde:
- `runtime`: AWS o local
- `action`: prepare-env, run, deploy

### Ejemplos

1. Preparar entorno local:
```bash
./zlambda -r local -a prepare-env
```

2. Ejecutar función localmente:
```bash
./zlambda -r local -a run
```

3. Desplegar a AWS:
```bash
./zlambda -r aws -a deploy
```

## Configuración

### lambda_config.json

Ejemplo de configuración:
```json
{
  "FunctionName": "mi-funcion",
  "Runtime": "python3.12",
  "Layers": [
    {
      "name": "mi-layer",
      "version": "1.0.0",
      "pip_lib": "requests==2.31.0"
    }
  ]
}
```

## Contribución

Las contribuciones son bienvenidas. Por favor, asegúrate de actualizar las pruebas según corresponda.

## Licencia

[MIT](https://choosealicense.com/licenses/mit/)
