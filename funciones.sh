#!/usr/bin/env bash
# -*- ENCODING: UTF-8 -*-
##
## @author     Raúl Caro Pastorino
## @copyright  Copyright © 2017 Raúl Caro Pastorino
## @license    https://wwww.gnu.org/licenses/gpl.txt
## @email      tecnico@fryntiz.es
## @web        www.fryntiz.es
## @github     https://github.com/fryntiz
## @gitlab     https://gitlab.com/fryntiz
## @twitter    https://twitter.com/fryntiz
##
##             Guía de estilos aplicada:
## @style      https://github.com/fryntiz/Bash_Style_Guide

############################
##     INSTRUCCIONES      ##
############################
## Este script tiene como objetivo reunir las funciones comunes para todos
## los demás scrips que componen el programa, con el fin de repetir la menor
## cantidad de código posible.

##
## Pide introducir un nombre para crear el proyecto
##
nombreProyecto() {
    ## Pide el nombre del proyecto
    while [[ -z "$nombre" ]]; do
        clear
        echo -e "$VE Introduce el nombre del proyecto$RO"
        read -p '  → ' nombre
        echo -e "$VE El nombre del proyecto introducido es$RO $nombre$CL"
    done
}

##
## Comprueba si ya existe este proyecto
##
compruebaExisteProyecto() {
    if [[ -d "$nombre" ]]; then
        echo -e "$RO Ya existe el directorio$AM $nombre$CL"
        echo -e "$VE ¿Quieres$RO BORRAR$VE y generarlo de nuevo?$RO"
        read -p '  s/N → ' opcion
        if [[ "$opcion" = 's' ]] || [[ "$opcion" = 'S' ]]; then
            rm -Rf "$nombre"
        else
            echo -e "$VE Has elegido no borrarlo, no se puede continuar$CL"
            exit 1
        fi
    fi
}

##
## Comprueba si los comandos recibidos existen
## $* Recibe los nombres de los comandos a comprobar
##
compruebaExisteComando() {
    local error=False

    for c in $*; do
        if [[ ! -x "/usr/bin/$c" ]]; then
            echo "No existe el comando $c"
            error=True
        fi
    done

    if [[ "$error" = 'True' ]]; then
        echo "$RO Instala los paquetes como dependencia antes de continuar$CL"
        exit 1
    fi
}

##
## Genera la estructura básica del proyecto
## @param  $1  String  Recibe la cadena con la ruta de la estructura
##
generarEstructura() {
    ## Crear el directorio si no existe
    if [[ ! -d "$nombre" ]]; then
        echo -e "$VE Creando directorio$RO $nombre$CL"
        mkdir "$nombre"
    fi

    ## Copia la estructura base dentro del proyecto
    echo -e "$VE Copiando esqueleto de proyecto...$CL"
    cp -aR $1/\. "./$nombre/"
}

##
## Crear BD con el nombre del proyecto
##
generarBD() {
    echo -e "$VE ¿Quieres crear un usuario psql y una BD para el proyecto?$CL"
    echo -e "$VE Esto borrará si existe alguna con ese nombre$RO"
    read -p '  s/N → ' opcion
    if [[ $opcion = 's' ]] || [[ $opcion = 'S' ]]; then
        echo -e "$VE Asegurando que postgreSQL está funcionando$CL"
        sudo service postgresql status > /dev/null || sudo service postgresql start

        echo -e "$VE Eliminando BD y usuario$RO $nombre$CL"
        sudo -u postgres dropdb --if-exists "$nombre"
        sudo -u postgres dropdb --if-exists "$nombre\_test"
        sudo -u postgres dropuser --if-exists "$nombre"

        ./$nombre/db/CrearDB.sh

        if [[ -f ./$nombre/db/Cargar_Datos.sh ]]; then
            echo -e "$VE Cargando datos en la BD$CL"
            ./$nombre/db/Cargar_Datos.sh
        fi
    else
        echo -e "$VE No se creará Base de Datos para el proyecto$CL"
        exit 1
    fi
}

##
## Establece permisos correspondientes para el nuevo proyecto
##
permisos() {
    echo -e "$VE Asignando dueños y permisos$CL"
    echo -e "$VE Usuario →$RO $USER$CL"
    echo -e "$VE Grupo   →$RO $USER$CL"
    chmod 755 -R "$nombre"
    chown "$USER:$USER" -R "$nombre"
}

##
## Establece permisos correspondientes para el nuevo proyecto WEB
##
permisosWEB() {
    echo -e "$VE Asignando dueños y permisos$CL"
    chmod 775 -R "$nombre"
    ownApache
}

##
## Establece dueño www-data para Apache 2
##
ownerApache() {
    echo -e "$VE Asignando dueño$RO $USER$VE y grupo$RO www-data$CL"
    chown "$USER:www-data" -R "$nombre"
}

##
## Crea un repositorio en remoto en github y sube los cambios
##
subir_github() {
    ## Preguntar si quiere subir a github el repositorio
    echo -e "$VE ¿Subir repositorio a GitHub?$CL"
    read -p '  s/N → ' input
    if [[ -f '/usr/local/bin/hub' ]] &&
       ([[ "$input" = s ]] || [[ "$input" = S ]])
    then
        ## Creo repositorio pidiendo descripción
        echo -e "$RO Descripción del repositorio:$AM"
        read -p '  → ' descripcion
        hub create -d "$descripcion"
        git push -u origin master
    fi
}

##
## Inicializa un repositorio GIT
## $1  String  Recibe el nombre del directorio donde inicializar
##
inicializar_GIT() {
    ## Pregunto si iniciar repositorio, si existe y no hay un directorio ".git"
    if [[ -d "$nombre" ]] && [[ ! -d "$nombre/.git" ]]; then
        local dirActual=$PWD

        ## Entrar al repositorio
        cd "$nombre" || return 0
        git init -q
        git add .
        git commit -q -m "Commit inicial de Proyecto recién generado"

        ## Llama a la función que sube el repositorio a GitHub
        subir_github

        cd "$dirActual" || exit 1
    fi
}
