# UMBRAL — Reparación de ventanas y personajes originales

Esta versión corrige el problema del dibujo de cabezas y óvalos en las ventanas.

## Correcciones

- El código ya **NO** dibuja nuevas cabezas, círculos, hombros ni óvalos.
- Las siluetas originales siguen siendo parte de los fondos de horror; los sprites de parkour azul y rojo se conservan sin cambios.
- Se incluyen nuevas imágenes de cristal **intacto**, obtenidas restaurando las grietas que ya venían en el arte original.
- El cristal comienza sin grietas (`window_damage=0`) y añade grietas en los niveles 1, 2 y 3.
- Las nuevas grietas usan PNG con **transparencia y una máscara de exclusión** sobre la cabeza del personaje y el marco. No pueden atravesarlos visualmente.
- Los fondos originales (`assets/backgrounds/horror_left.png` y `horror_right.png`) se conservan sin modificaciones para poder recuperarlos.

## Abrir

1. Extrae este ZIP a una carpeta nueva.
2. En Godot 4.x, importa `UMBRAL_Ventanas_Reparadas/project.godot`.
3. Espera a que se importen los recursos y presiona F5.
4. Comprueba primero la ventana intacta de J2, luego los niveles de daño de J1.

**Nota:** no se ha ejecutado Godot en este entorno; los assets generados, el código y sus rutas se han revisado estáticamente.
