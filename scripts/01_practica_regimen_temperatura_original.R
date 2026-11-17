
# SESIÓN PRÁCTICA: RÉGIMEN DE TEMPERATURA

#Objetivos:

#1. Calcular las temperaturas medias, máximas y mínimas mensuales a partir de una serie histórica de 25 años.

#2. Determinar la amplitud térmica diaria promedio mensual y la amplitud térmica del ciclo anual medio.

#3. Representar gráficamente la variación mensual de las temperaturas y las amplitudes térmicas.

#4. Interpretar los resultados para identificar los patrones estacionales y caracterizar el comportamiento térmico de la localidad estudiada.


#Descargamos la precipitación de la estación de interés --------------------------------------------------------------

#Usaremos como ejemplo algun sitio experimental:

lat <- 9.2371 #Modificar las coordenadas de acuerdo a tu estación 
lon <- -66.2158
altitud <- 490.87

# Instalamos los paquetes necesarios--------------------------------------------------------------
install.packages(c(
  "tidyverse",
  "lubridate",
  "nasapower",
  "terra",
  "sf",
  "ggplot2",
  "openxlsx"
))

# Cargamos los paquetes--------------------------------------------------------------
library(tidyverse)
library(lubridate)
library(nasapower)
library(terra)
library(sf)
library(ggplot2)
library(openxlsx)

#Creamos la estructura de carpetas donde se guardaran los resultados --------------------------------------------------------------
dir.create("datos", showWarnings = FALSE)

#Descargar datos diarios desde NASA POWER--------------------------------------------------------------

datos_power <- get_power(
  community = "AG",
  lonlat = c(lon, lat),
  pars = c(
    "T2M",
    "T2M_MAX",
    "T2M_MIN",
    "PRECTOTCORR",
    "RH2M",
    "WS2M",
    "ALLSKY_SFC_SW_DWN",
    "CLRSKY_SFC_SW_DWN"
  ),
  dates = c("2001-01-01", "2025-12-31"), #En este punto colocamos el intervalo de fechas que deseemos 
  temporal_api = "DAILY"
)

#Ordenar y limpiar los datos--------------------------------------------------------------

datos_power_limpios <- datos_power %>%
  mutate(
    fecha = ymd(YYYYMMDD)
  ) %>%
  select(
    fecha,
    T_media = T2M,
    T_max = T2M_MAX,
    T_min = T2M_MIN,
    P_mm = PRECTOTCORR,
    HR = RH2M,
    Viento = WS2M,
    Radiacion = ALLSKY_SFC_SW_DWN,
    Radiacion_cielo_despejado = CLRSKY_SFC_SW_DWN
  )

# Y luego exportar sin los números de fila
write.csv(datos_power_limpios, "datos/datos_diarios_2001_2025.csv", row.names = FALSE)


# Leer datos --------------------------------------------------------------
# Instalar una sola vez si es necesario: install.packages("openxlsx")
archivo <- "datos/datos_diarios_2001_2025.xlsx"
if (!file.exists(archivo)) stop("No se encuentra: ", archivo)
if (!requireNamespace("openxlsx", quietly = TRUE)) {
  stop("Instale openxlsx: install.packages('openxlsx')")
}

datos <- openxlsx::read.xlsx(archivo, detectDates = TRUE)
requeridas <- c("fecha", "T_media", "T_max", "T_min")
if (!all(requeridas %in% names(datos))) {
  stop("Faltan columnas: ", paste(setdiff(requeridas, names(datos)), collapse = ", "))
}

# Convertir las fechas de Excel cuando sea necesario.
if (inherits(datos$fecha, "POSIXt")) {
  datos$fecha <- as.Date(datos$fecha)
} else if (is.numeric(datos$fecha)) {
  datos$fecha <- as.Date(datos$fecha, origin = "1899-12-30")
} else {
  datos$fecha <- as.Date(datos$fecha)
}
for (v in c("T_media", "T_max", "T_min")) {
  datos[[v]] <- as.numeric(datos[[v]])
}
if (anyNA(datos[, requeridas])) stop("Hay fechas o temperaturas faltantes/no válidas.")
if (anyDuplicated(datos$fecha)) stop("Hay fechas duplicadas.")
if (any(datos$T_max < datos$T_min)) stop("Hay días con T_max menor que T_min.")

datos <- datos[order(datos$fecha), ]
datos$anio <- as.integer(format(datos$fecha, "%Y"))
datos$mes <- as.integer(format(datos$fecha, "%m"))
datos$ATD <- datos$T_max - datos$T_min

cat("\nPeríodo analizado:", min(datos$anio), "a", max(datos$anio), "\n")
cat("Días disponibles:", nrow(datos), "\n")

# TEMPERATURAS MEDIAS MENSUALES (TODOS LOS AÑOS) ---------------------------
# Primer paso: promedio de los datos diarios dentro de cada mes de cada año.
por_anio_mes <- aggregate(
  cbind(T_media, T_max, T_min, ATD) ~ anio + mes,
  data = datos, FUN = mean
)

# Segundo paso: promedio entre años para cada mes del calendario.
# Cada año tiene el mismo peso, incluso cuando el número de días del mes difiere.
mensual <- aggregate(
  cbind(T_media, T_max, T_min, ATD) ~ mes,
  data = por_anio_mes, FUN = mean
)
mensual <- mensual[order(mensual$mes), ]
mensual$Mes <- month.abb[mensual$mes]

cat("\nTEMPERATURAS Y AMPLITUD TÉRMICA MEDIA POR MES (°C)\n")
print(round(mensual[, c("T_media", "T_max", "T_min", "ATD")], 2))

# GRÁFICO 1: evolución media anual de temperatura
matplot(mensual$mes,
        cbind(mensual$T_max, mensual$T_media, mensual$T_min),
        type = "b", pch = c(17, 19, 15), lty = 1,
        col = c("tomato3", "darkgreen", "steelblue"),
        xaxt = "n", xlab = "Mes", ylab = "Temperatura (°C)",
        main = "Ciclo anual medio de temperatura (2001–2025)")
axis(1, at = 1:12, labels = month.abb)
legend("topright", legend = c("T máxima", "T media", "T mínima"),
       col = c("tomato3", "darkgreen", "steelblue"),
       pch = c(17, 19, 15), lty = 1, bty = "n")

# 2. AMPLITUD TÉRMICA --------------------------------------------------------
# Amplitud térmica diaria (ATD) = Tmax diaria - Tmin diaria.
# Se muestra el promedio mensual de las ATD de todos los años.
barplot(mensual$ATD, names.arg = mensual$Mes, col = "skyblue",
        main = "Amplitud térmica diaria media por mes (2001–2025)",
        xlab = "Mes", ylab = "ATD media (°C)")

# Amplitud térmica del ciclo anual medio:
# diferencia entre la temperatura media del mes más cálido y la del más frío.
mes_calido <- which.max(mensual$T_media)
mes_frio <- which.min(mensual$T_media)
amplitud_ciclo_anual <- max(mensual$T_media) - min(mensual$T_media)

cat("\nMes más cálido:", mensual$Mes[mes_calido], "\n")
cat("Mes más frío:", mensual$Mes[mes_frio], "\n")
cat("Amplitud térmica del ciclo anual medio:",
    round(amplitud_ciclo_anual, 2), "°C\n")
cat("ATD promedio de todo el período:", round(mean(datos$ATD), 2), "°C\n")

# 3. EXPORTAR RESULTADOS -----------------------------------------------------
dir.create("resultados", showWarnings = FALSE)
write.csv(por_anio_mes, "resultados/temperatura_por_anio_y_mes.csv", row.names = FALSE)
write.csv(mensual, "resultados/temperatura_promedio_mensual_2001_2025.csv", row.names = FALSE)
resumen <- data.frame(
  periodo = paste0(min(datos$anio), "-", max(datos$anio)),
  mes_mas_calido = mensual$Mes[mes_calido],
  mes_mas_frio = mensual$Mes[mes_frio],
  amplitud_ciclo_anual_C = round(amplitud_ciclo_anual, 2),
  ATD_promedio_C = round(mean(datos$ATD), 2)
)
write.csv(resumen, "resultados/resumen_regimen_temperatura.csv", row.names = FALSE)
cat("\nTablas guardadas en resultados/.\n")

# PREGUNTAS DE ANÁLISIS ------------------------------------------------------
# 1. ¿Cuáles son los meses con mayor y menor temperatura media en 2001–2025?
# 2. ¿Cuál es la amplitud térmica del ciclo anual medio?
# 3. ¿En qué mes se observa la mayor amplitud térmica diaria promedio y por qué?
# 4. ¿Qué diferencias estacionales muestran las temperaturas y la amplitud diaria?
