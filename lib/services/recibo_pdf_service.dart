import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Servicio para la generación, previsualización, impresión y exportación en PDF
/// de los Recibos Oficiales de Cobranza (Vista E3 del Plan de Control Económico).
class ReciboPdfService {
  /// Genera los bytes del documento PDF con diseño oficial institucional.
  static Future<Uint8List> generarPdfRecibo(Map<String, dynamic> datos) async {
    final pdf = pw.Document();

    final nroRecibo = datos['nro_recibo']?.toString() ?? 'REC-0000-000000';
    final fecha = datos['fecha']?.toString() ?? '';
    final hora = datos['hora']?.toString() ?? '';
    final conductorNombre = datos['conductor_nombre']?.toString() ?? 'Conductor';
    final conductorCi = datos['conductor_ci']?.toString() ?? 'S/CI';
    final tipoNombre = datos['tipo_nombre']?.toString() ?? 'Cuota';
    final concepto = datos['concepto']?.toString() ?? tipoNombre;
    final montoPagado = (datos['monto_pagado'] as num?)?.toDouble() ?? 0.0;
    final totalCuota = (datos['total_cuota'] as num?)?.toDouble() ?? montoPagado;
    final saldoRestante = (datos['saldo_restante'] as num?)?.toDouble() ?? 0.0;
    final metodo = (datos['metodo']?.toString() ?? 'efectivo').toUpperCase();
    final cobrador = datos['cobrador_nombre']?.toString() ?? 'Secretario de Hacienda';
    final observacion = datos['observacion']?.toString() ?? '';

    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(
          base: fontRegular,
          bold: fontBold,
        ),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(18),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue900, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // 1. CABECERA INSTITUCIONAL
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SINDICATO MIXTO DE TRANSPORTES',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue900,
                          ),
                        ),
                        pw.Text(
                          'CONTINENTAL TRUFI',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blue800,
                          ),
                        ),
                        pw.Text(
                          'SECRETARÍA DE HACIENDA Y CONTROL ECONÓMICO',
                          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        border: pw.Border.all(color: PdfColors.blue800, width: 1),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.center,
                        children: [
                          pw.Text(
                            'RECIBO DE COBRO',
                            style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            nroRecibo,
                            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.red800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1, color: PdfColors.blue900),
                pw.SizedBox(height: 6),

                // 2. METADATOS: FECHA Y COBRADOR
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Fecha: $fecha  Hora: $hora', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                    pw.Text('Cobrado por: $cobrador', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                  ],
                ),

                pw.SizedBox(height: 10),

                // 3. DATOS DEL CONDUCTOR
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        children: [
                          pw.Text('Recibido de: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                          pw.Expanded(
                            child: pw.Text(
                              conductorNombre.toUpperCase(),
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.blue900),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      pw.Row(
                        children: [
                          pw.Text('Cédula de Identidad: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.Text(conductorCi, style: const pw.TextStyle(fontSize: 9)),
                          pw.Spacer(),
                          pw.Text('Método de pago: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                          pw.Text(metodo, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 12),

                // 4. DETALLE DE LA OBLIGACIÓN / CONCEPTO
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1.2),
                    2: const pw.FlexColumnWidth(1.2),
                    3: const pw.FlexColumnWidth(1.2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.blue800),
                      children: [
                        _buildTableHeader('Concepto / Cuota'),
                        _buildTableHeader('Total Oblig.'),
                        _buildTableHeader('Abonado'),
                        _buildTableHeader('Saldo Rest.'),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(tipoNombre, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                              pw.Text(concepto, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                              if (observacion.isNotEmpty)
                                pw.Text('Obs: $observacion', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                            ],
                          ),
                        ),
                        _buildTableCell('Bs. ${totalCuota.toStringAsFixed(2)}'),
                        _buildTableCell('Bs. ${montoPagado.toStringAsFixed(2)}', esBold: true, color: PdfColors.green800),
                        _buildTableCell('Bs. ${saldoRestante.toStringAsFixed(2)}', color: saldoRestante > 0 ? PdfColors.red800 : PdfColors.grey700),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 12),

                // 5. CAJA DE TOTAL DESTACADO
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green50,
                        border: pw.Border.all(color: PdfColors.green700, width: 1),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Text('TOTAL COBRADO:  ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                          pw.Text(
                            'Bs. ${montoPagado.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                pw.Spacer(),

                // 6. FIRMAS DE CONFORMIDAD
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                  children: [
                    pw.Column(
                      children: [
                        pw.Container(width: 140, height: 1, color: PdfColors.grey500),
                        pw.SizedBox(height: 4),
                        pw.Text('Firma del Conductor', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text(conductorNombre, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                      ],
                    ),
                    pw.Column(
                      children: [
                        pw.Container(width: 140, height: 1, color: PdfColors.grey500),
                        pw.SizedBox(height: 4),
                        pw.Text('Secretaría de Hacienda / Sello', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text(cobrador, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),
                pw.Center(
                  child: pw.Text(
                    'Sistema Continental Trufi - Comprobante de descargo oficial válido',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildTableHeader(String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        texto,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(color: PdfColors.white, fontSize: 8.5, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _buildTableCell(String texto, {bool esBold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        texto,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: esBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  /// Abre la pantalla de visualización / impresión / compartir en Flutter.
  static Future<void> mostrarVistaPrevia(BuildContext context, Map<String, dynamic> datosPago) async {
    final bytes = await generarPdfRecibo(datosPago);
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long, color: Color(0xFF1E3A8A), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recibo de Cobranza',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                          ),
                          Text(
                            datosPago['nro_recibo']?.toString() ?? '',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: PdfPreview(
                build: (format) => bytes,
                canChangeOrientation: false,
                canChangePageFormat: false,
                allowPrinting: true,
                allowSharing: true,
                pdfFileName: '${datosPago['nro_recibo'] ?? 'recibo'}.pdf',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Genera los bytes de un informe económico en formato PDF (Vista E12).
  static Future<Uint8List> generarPdfInformeEconomico(Map<String, dynamic> datos) async {
    final pdf = pw.Document();
    final fechaDesde = datos['fecha_desde']?.toString() ?? 'Inicio histórico';
    final fechaHasta = datos['fecha_hasta']?.toString() ?? 'Hoy';
    final recaudado = (datos['gran_total_recaudado'] as num?)?.toDouble() ?? 0.0;
    final pendiente = (datos['gran_total_pendiente'] as num?)?.toDouble() ?? 0.0;
    final total = recaudado + pendiente;
    final porcentaje = total > 0 ? ((recaudado / total) * 100) : 0.0;
    final tipos = (datos['comparativa_tipos'] as List<dynamic>?) ?? [];

    final fontRegular = await PdfGoogleFonts.interRegular();
    final fontBold = await PdfGoogleFonts.interBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: fontRegular, bold: fontBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. Cabecera
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('SINDICATO MIXTO DE TRANSPORTES', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Text('CONTINENTAL TRUFI', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      pw.Text('SECRETARÍA DE HACIENDA Y CONTROL ECONÓMICO', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INFORME ECONÓMICO', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      pw.Text('Período: $fechaDesde  a  $fechaHasta', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                      pw.Text('Generado: ${DateTime.now().toIso8601String().substring(0, 16).replaceAll('T', ' ')}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
                    ],
                  ),
                ],
              ),
              pw.Divider(thickness: 1.5, color: PdfColors.blue900),
              pw.SizedBox(height: 14),

              // 2. Resumen Métricas
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green50,
                        border: pw.Border.all(color: PdfColors.green700, width: 1),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('TOTAL RECAUDADO', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                          pw.SizedBox(height: 4),
                          pw.Text('Bs. ${recaudado.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.red50,
                        border: pw.Border.all(color: PdfColors.red700, width: 1),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('TOTAL PENDIENTE', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                          pw.SizedBox(height: 4),
                          pw.Text('Bs. ${pendiente.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        border: pw.Border.all(color: PdfColors.blue700, width: 1),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('EFECTIVIDAD DE COBRO', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                          pw.SizedBox(height: 4),
                          pw.Text('${porcentaje.toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // 3. Tabla Desglosada por Tipo de Cuota
              pw.Text('BALANCE COMPARATIVO POR TIPO DE CUOTA', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              pw.SizedBox(height: 8),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                    children: [
                      _buildTableHeader('Concepto / Tipo de Cuota'),
                      _buildTableHeader('Recaudado (Bs.)'),
                      _buildTableHeader('Pendiente (Bs.)'),
                      _buildTableHeader('Comprometido (Bs.)'),
                    ],
                  ),
                  ...tipos.map((t) {
                    final rec = (t['recaudado'] as num?)?.toDouble() ?? 0.0;
                    final pend = (t['pendiente'] as num?)?.toDouble() ?? 0.0;
                    final comp = (t['total_comprometido'] as num?)?.toDouble() ?? (rec + pend);
                    return pw.TableRow(
                      children: [
                        _buildTableCell(t['tipo_nombre']?.toString() ?? '', esBold: true),
                        _buildTableCell('Bs. ${rec.toStringAsFixed(2)}', color: PdfColors.green800),
                        _buildTableCell('Bs. ${pend.toStringAsFixed(2)}', color: pend > 0 ? PdfColors.red800 : PdfColors.grey700),
                        _buildTableCell('Bs. ${comp.toStringAsFixed(2)}'),
                      ],
                    );
                  }),
                  // Fila Totales
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      _buildTableCell('TOTALES GENERALES', esBold: true),
                      _buildTableCell('Bs. ${recaudado.toStringAsFixed(2)}', esBold: true, color: PdfColors.green900),
                      _buildTableCell('Bs. ${pendiente.toStringAsFixed(2)}', esBold: true, color: PdfColors.red900),
                      _buildTableCell('Bs. ${total.toStringAsFixed(2)}', esBold: true),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // 4. Firmas
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 150, height: 1, color: PdfColors.grey500),
                      pw.SizedBox(height: 4),
                      pw.Text('Secretario de Hacienda', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Control y Recaudaciones', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 150, height: 1, color: PdfColors.grey500),
                      pw.SizedBox(height: 4),
                      pw.Text('Secretario General', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Sindicato Continental Trufi', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Text(
                  'Documento Oficial de Rendición de Cuentas - Sistema Integral Continental Trufi',
                  style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Abre la pantalla de visualización / impresión / compartir del informe económico en PDF.
  static Future<void> mostrarVistaPreviaInforme(BuildContext context, Map<String, dynamic> datosInforme) async {
    final bytes = await generarPdfInformeEconomico(datosInforme);
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.90,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.analytics_outlined, color: Color(0xFF1E3A8A), size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Informe Económico Oficial',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                          ),
                          Text(
                            'Balance Recaudado vs. Pendiente',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: PdfPreview(
                build: (format) => bytes,
                canChangeOrientation: false,
                canChangePageFormat: false,
                allowPrinting: true,
                allowSharing: true,
                pdfFileName: 'informe_economico_continental.pdf',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Genera un informe completo en PDF con el estado de cuotas de todos los conductores.
  static Future<Uint8List> generarPdfInformeCuotasConductores({
    required String tituloCuota,
    String? motivoCuota,
    required double montoSugerido,
    required List<Map<String, dynamic>> conductores,
    required double totalRecaudado,
    required double totalFalta,
    required int totalConductores,
    required int cantPagados,
    required int cantDeben,
    String emitidoPor = 'Secretaría de Hacienda',
  }) async {
    final pdf = pw.Document();
    final fechaHoy = DateTime.now();
    final fechaStr = '${fechaHoy.day.toString().padLeft(2, '0')}/${fechaHoy.month.toString().padLeft(2, '0')}/${fechaHoy.year} ${fechaHoy.hour.toString().padLeft(2, '0')}:${fechaHoy.minute.toString().padLeft(2, '0')}';
    final totalMeta = totalRecaudado + totalFalta;
    final porcentajeRecaudado = totalMeta > 0 ? (totalRecaudado / totalMeta * 100) : 0.0;

    pw.ThemeData tema;
    try {
      final fontRegular = await PdfGoogleFonts.interRegular();
      final fontBold = await PdfGoogleFonts.interBold();
      tema = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);
    } catch (_) {
      tema = pw.ThemeData.base();
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(28),
        theme: tema,
        header: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'SINDICATO MIXTO DE TRANSPORTES CONTINENTAL TRUFI',
                        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      pw.Text(
                        'SECRETARÍA DE HACIENDA Y CONTROL ECONÓMICO',
                        style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INFORME DE CONTROL DE CUOTAS',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      pw.Text(
                        'Fecha: $fechaStr',
                        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 1, color: PdfColors.blue900),
              pw.SizedBox(height: 8),
            ],
          );
        },
        footer: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Generado por: $emitidoPor', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                  pw.Text('Página ${context.pageNumber} de ${context.pagesCount}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
        build: (pw.Context context) {
          return [
            // 1. TÍTULO Y DETALLE DE LA CUOTA
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                border: pw.Border.all(color: PdfColors.blue300, width: 0.8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'CUOTA EVALUADA:',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                        pw.Text(
                          tituloCuota,
                          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                        ),
                        if (motivoCuota != null && motivoCuota.trim().isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Motivo: ${motivoCuota.trim()}',
                            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey800),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'MONTO FIJADO:',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
                      ),
                      pw.Text(
                        'Bs. ${montoSugerido.toStringAsFixed(2)} c/u',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // 2. TRES TARJETAS DE RESUMEN EJECUTIVO
            pw.Row(
              children: [
                // Pagaron
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: PdfColors.green600, width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TOTAL RECAUDADO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                        pw.SizedBox(height: 2),
                        pw.Text('Bs. ${totalRecaudado.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                        pw.Text('$cantPagados de $totalConductores pagaron (${porcentajeRecaudado.toStringAsFixed(1)}%)', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.green900)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                // Falta cobrar
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.red50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: PdfColors.red600, width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TOTAL PENDIENTE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                        pw.SizedBox(height: 2),
                        pw.Text('Bs. ${totalFalta.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.red800)),
                        pw.Text('$cantDeben conductores con deuda', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.red900)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 8),
                // Total meta
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: PdfColors.blue800, width: 0.8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TOTAL DE TODO', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.SizedBox(height: 2),
                        pw.Text('Bs. ${totalMeta.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                        pw.Text('$totalConductores conductores activos', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.blue900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // 3. TABLA DE TODOS LOS CONDUCTORES
            pw.Text(
              'DETALLE INDIVIDUAL DE CONDUCTORES',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900),
            ),
            pw.SizedBox(height: 6),

            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              columnWidths: {
                0: const pw.FixedColumnWidth(24),
                1: const pw.FlexColumnWidth(3.5),
                2: const pw.FlexColumnWidth(1.6),
                3: const pw.FlexColumnWidth(1.8),
                4: const pw.FlexColumnWidth(1.8),
                5: const pw.FlexColumnWidth(1.8),
                6: const pw.FlexColumnWidth(1.5),
              },
              children: [
                // Encabezados
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue900),
                  children: [
                    _buildCell('#', isHeader: true, align: pw.TextAlign.center),
                    _buildCell('Conductor', isHeader: true),
                    _buildCell('C.I.', isHeader: true),
                    _buildCell('Total (Bs.)', isHeader: true, align: pw.TextAlign.right),
                    _buildCell('Pagó (Bs.)', isHeader: true, align: pw.TextAlign.right),
                    _buildCell('Falta (Bs.)', isHeader: true, align: pw.TextAlign.right),
                    _buildCell('Estado', isHeader: true, align: pw.TextAlign.center),
                  ],
                ),
                // Filas de cada conductor
                ...conductores.asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  final nombre = c['conductor_nombre']?.toString() ?? 'Conductor';
                  final ci = c['conductor_ci']?.toString() ?? '';
                  final pagado = (c['monto_pagado'] as num?)?.toDouble() ?? 0.0;
                  final falta = (c['monto_falta'] as num?)?.toDouble() ?? 0.0;
                  final total = (c['monto_total'] as num?)?.toDouble() ?? 0.0;
                  final alDia = falta <= 0.001;
                  final bgFila = i % 2 == 1 ? PdfColors.grey100 : PdfColors.white;

                  return pw.TableRow(
                    decoration: pw.BoxDecoration(color: bgFila),
                    children: [
                      _buildCell('${i + 1}', align: pw.TextAlign.center),
                      _buildCell(nombre, esBold: true),
                      _buildCell(ci),
                      _buildCell(total.toStringAsFixed(2), align: pw.TextAlign.right),
                      _buildCell(pagado.toStringAsFixed(2), align: pw.TextAlign.right, color: PdfColors.green800, esBold: pagado > 0),
                      _buildCell(falta.toStringAsFixed(2), align: pw.TextAlign.right, color: falta > 0 ? PdfColors.red800 : PdfColors.grey600),
                      _buildCell(alDia ? 'AL DÍA' : 'DEBE', align: pw.TextAlign.center, color: alDia ? PdfColors.green800 : PdfColors.red800, esBold: true),
                    ],
                  );
                }),
                // Fila de Totales
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                  children: [
                    _buildCell('', isHeader: true),
                    _buildCell('TOTALES', isHeader: true, esBold: true),
                    _buildCell('$totalConductores cond.', isHeader: true),
                    _buildCell(totalMeta.toStringAsFixed(2), isHeader: true, align: pw.TextAlign.right, esBold: true),
                    _buildCell(totalRecaudado.toStringAsFixed(2), isHeader: true, align: pw.TextAlign.right, color: PdfColors.green900, esBold: true),
                    _buildCell(totalFalta.toStringAsFixed(2), isHeader: true, align: pw.TextAlign.right, color: PdfColors.red900, esBold: true),
                    _buildCell('$cantPagados/$totalConductores', isHeader: true, align: pw.TextAlign.center, esBold: true),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // 4. FIRMAS
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Container(width: 150, height: 1, color: PdfColors.grey600),
                    pw.SizedBox(height: 4),
                    pw.Text('Secretario de Hacienda', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Control Económico', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(width: 150, height: 1, color: PdfColors.grey600),
                    pw.SizedBox(height: 4),
                    pw.Text('Secretario General', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Sindicato Continental Trufi', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey600)),
                  ],
                ),
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildCell(
    String texto, {
    bool isHeader = false,
    bool esBold = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(
        texto,
        textAlign: align,
        style: pw.TextStyle(
          fontSize: isHeader ? 8 : 7.5,
          fontWeight: (isHeader || esBold) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? (isHeader ? PdfColors.white : PdfColors.black),
        ),
      ),
    );
  }

  /// Abre la pantalla de visualización / impresión / compartir del informe de cuotas de conductores.
  static Future<void> mostrarVistaPreviaInformeCuotas(
    BuildContext context, {
    required String tituloCuota,
    String? motivoCuota,
    required double montoSugerido,
    required List<Map<String, dynamic>> conductores,
    required double totalRecaudado,
    required double totalFalta,
    required int totalConductores,
    required int cantPagados,
    required int cantDeben,
  }) async {
    final bytes = await generarPdfInformeCuotasConductores(
      tituloCuota: tituloCuota,
      motivoCuota: motivoCuota,
      montoSugerido: montoSugerido,
      conductores: conductores,
      totalRecaudado: totalRecaudado,
      totalFalta: totalFalta,
      totalConductores: totalConductores,
      cantPagados: cantPagados,
      cantDeben: cantDeben,
    );
    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.picture_as_pdf, color: Color(0xFF1E3A8A), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informe Oficial de Cuotas',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                          ),
                          Text(
                            tituloCuota,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: PdfPreview(
                build: (format) => bytes,
                canChangeOrientation: false,
                canChangePageFormat: false,
                allowPrinting: true,
                allowSharing: true,
                pdfFileName: 'informe_cuotas_${tituloCuota.replaceAll(' ', '_').toLowerCase()}.pdf',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

