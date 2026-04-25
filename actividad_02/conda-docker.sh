#!/bin/bash

# ENV_NAME=env_pyspark
# docker exec -it anaconda_worker conda create --name ${ENV_NAME} python=3.12 anaconda
# docker exec -it anaconda_worker conda activatge ${ENV_NAME}

# Nombre del contenedor
CONTAINER_NAME="anaconda_dev"

show_help() {
  echo "Uso: ./conda-docker.sh [opciones]"
  echo ""
  echo "Opciones:"
  echo "  -n, --name      Nombre del ambiente"
  echo "  -v, --version   Versión de Python (default: 3.9)"
  echo "  -c, --create    Crea el ambiente"
  echo "  -a, --activate  Registra el ambiente en Jupyter"
  echo "  -r, --remove    Elimina el ambiente"
  echo "  -i, --install   Instala paquetes (ej: -i \"numpy pandas\")"
  echo "  -l, --list      Lista los ambientes"
  echo "  -h, --help      Muestra esta ayuda"
}

if [[ $# -eq 0 ]]; then show_help; exit 0; fi

while [[ $# -gt 0 ]]; do
  case $1 in
    -n|--name) ENV_NAME="$2"; shift 2 ;;
    -v|--version) PYTHON_VER="$2"; shift 2 ;;
    -c|--create) CREATE=true; shift ;;
    -a|--activate) ACTIVATE=true; shift ;;
    -r|--remove) REMOVE=true; shift ;;
    -i|--install) PACKAGES="$2"; shift 2 ;;
    -l|--list) LIST=true; shift ;;
    *) echo "Opción desconocida: $1"; exit 1 ;;
  esac
done

# Listar
if [ "$LIST" = true ]; then
    docker exec -it "$CONTAINER_NAME" conda env list
    exit 0
fi

# Validar nombre para operaciones críticas
if [ -z "$ENV_NAME" ] && ([ "$CREATE" = true ] || [ "$ACTIVATE" = true ] || [ "$REMOVE" = true ] || [ -n "$PACKAGES" ]); then
    echo "Error: Se requiere un nombre (-n)"
    exit 1
fi

# Eliminar
if [ "$REMOVE" = true ]; then
    echo "Eliminando ambiente '$ENV_NAME'..."
    docker exec -it "$CONTAINER_NAME" jupyter kernelspec uninstall "$ENV_NAME" -f 2>/dev/null
    docker exec -it "$CONTAINER_NAME" conda env remove --name "$ENV_NAME" -y
    echo "Ambiente eliminado."
    exit 0
fi

# Crear
if [ "$CREATE" = true ]; then
    VER=${PYTHON_VER:-"3.9"}
    docker exec -it "$CONTAINER_NAME" conda create --name "$ENV_NAME" python="$VER" -y
fi

# Instalar paquetes extra
if [ -n "$PACKAGES" ]; then
    echo "Instalando paquetes: $PACKAGES..."
    docker exec -it "$CONTAINER_NAME" conda install --name "$ENV_NAME" $PACKAGES -y
fi

# Acción: Activar (Registrar en Jupyter)
if [ "$ACTIVATE" = true ]; then
    echo "Registrando '$ENV_NAME' en Jupyter..."
    docker exec -it "$CONTAINER_NAME" conda run -n "$ENV_NAME" conda install ipykernel -y
    docker exec -it "$CONTAINER_NAME" conda run -n "$ENV_NAME" conda install openjdk -y
    docker exec -it "$CONTAINER_NAME" conda run -n "$ENV_NAME" conda install pyspark -y
    docker exec -it "$CONTAINER_NAME" conda run -n "$ENV_NAME" conda install -c conda-forge findspark -y
    docker exec -it "$CONTAINER_NAME" conda run -n "$ENV_NAME" python -m ipykernel install --user --name "$ENV_NAME" --display-name "Python ($ENV_NAME)"
    echo "El ambiente ya está disponible en Jupyter."
fi


# ./conda-docker.sh --create --name env-pyspark --version 3.12
# ./conda-docker.sh --activate --name env-pyspark
# ./conda-docker.sh --remove --name env-pyspark

# Crear e instalar a la vez
# ./conda-docker.sh -c -n env-pyspark -i "pandas scikit-learn matplotlib"

# Instalar en un ambiente existente
# ./conda-docker.sh -n env-pyspark -i "seaborn"