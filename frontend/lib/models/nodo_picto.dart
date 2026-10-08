// Ruta: lib/models/nodo_picto.dart
import 'package:flutter/material.dart';

class NodoPicto {
  final String palabra;
  final String palabraBusqueda;
  final int? idArasaac;
  String url; // Se mantiene mutable para el motor JIT
  final Color colorFondo;
  final bool esCarpeta;
  final List<NodoPicto>? contenido;

  NodoPicto({
    required this.palabra,
    String? palabraBusqueda,
    this.idArasaac,
    String? url,
    this.colorFondo = Colors.white,
    this.esCarpeta = false,
    this.contenido,
  }) : palabraBusqueda = palabraBusqueda ?? palabra.toLowerCase(),
       url =
           url ??
           (idArasaac != null
               ? 'https://static.arasaac.org/pictograms/$idArasaac/${idArasaac}_300.png'
               : "");

  // --- ESCALABILIDAD: DESERIALIZACIÓN (Backend -> App) ---
  factory NodoPicto.fromJson(Map<String, dynamic> json) {
    return NodoPicto(
      palabra: json['palabra'] ?? '',
      palabraBusqueda: json['palabra_busqueda'],
      idArasaac: json['id_arasaac'],
      url: json['url'],
      // Convierte el entero numérico (ej. 4294967295) de vuelta a objeto Color
      colorFondo: json['color_fondo'] != null
          ? Color(json['color_fondo'])
          : Colors.white,
      esCarpeta: json['es_carpeta'] ?? false,
      contenido: json['contenido'] != null
          ? (json['contenido'] as List)
                .map((i) => NodoPicto.fromJson(i))
                .toList()
          : null,
    );
  }

  // --- ESCALABILIDAD: SERIALIZACIÓN (App -> Caché local o Backend) ---
  Map<String, dynamic> toJson() {
    return {
      'palabra': palabra,
      'palabra_busqueda': palabraBusqueda,
      'id_arasaac': idArasaac,
      'url': url,
      // Extrae el valor numérico del color para poder guardarlo en JSON
      'color_fondo': colorFondo.value,
      'es_carpeta': esCarpeta,
      'contenido': contenido?.map((nodo) => nodo.toJson()).toList(),
    };
  }
}
