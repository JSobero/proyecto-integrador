import 'package:flutter/material.dart';

class NodoPicto {
  final String palabra;
  final String palabraBusqueda;
  final int? idArasaac; // NUEVO: Permite forzar una imagen exacta
  String url;
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
       // Si nos das un ID, armamos la URL al instante sin consultar a la API
       url =
           url ??
           (idArasaac != null
               ? 'https://static.arasaac.org/pictograms/$idArasaac/${idArasaac}_300.png'
               : "");
}
