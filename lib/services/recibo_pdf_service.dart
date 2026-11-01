import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'economia_repo.dart';

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
    String? categoria,
    List<Map<String, dynamic>>? cuotasCronograma,
    String emitidoPor = 'Secretaría de Hacienda',
  }) async {
    final pdf = pw.Document();
    final fechaHoy = DateTime.now();
    final fechaStr = '${fechaHoy.day.toString().padLeft(2, '0')}/${fechaHoy.month.toString().padLeft(2, '0')}/${fechaHoy.year} ${fechaHoy.hour.toString().padLeft(2, '0')}:${fechaHoy.minute.toString().padLeft(2, '0')}';
    final totalMeta = totalRecaudado + totalFalta;

    // Determinar si es Canastón / Cuota con múltiples fechas programadas
    final listaCronograma = cuotasCronograma ?? const [];
    final fechasUnicasSet = <String>{};
    for (final row in listaCronograma) {
      final f = row['fecha_programada']?.toString().trim() ?? '';
      if (f.isNotEmpty) fechasUnicasSet.add(f);
    }
    final fechasUnicas = fechasUnicasSet.toList()..sort();
    final esCanaston =
        (categoria?.toLowerCase() == 'canaston' || fechasUnicas.length > 1) &&
            fechasUnicas.isNotEmpty;

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
          // Extraer Beneficiario y Modalidad si existen
          String? beneficiario;
          String? modalidad;
          String? motivoTexto;

          if (motivoCuota != null && motivoCuota.trim().isNotEmpty) {
            if (motivoCuota.contains('|')) {
              for (final part in motivoCuota.split('|')) {
                final p = part.trim();
                if (p.startsWith('Beneficiario:')) {
                  beneficiario = p.replaceFirst('Beneficiario:', '').trim();
                } else if (p.startsWith('Modalidad:')) {
                  modalidad = p.replaceFirst('Modalidad:', '').trim();
                } else if (p.startsWith('Motivo:')) {
                  motivoTexto = p.replaceFirst('Motivo:', '').trim();
                }
              }
            } else {
              motivoTexto = motivoCuota.trim();
            }
          }

          return [
            // 1. BANNER / TÍTULO CENTRADO
            pw.Center(
              child: pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 5.5,
                ),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF0F3A78),
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Text(
                  'INFORME DE PAGOS',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ),
            pw.SizedBox(height: 9),

            // 2. DASHBOARD RESUMEN DE COBROS (UN CUADRADO CON LOS 3 TOTALES)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF8FAFD),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(9)),
                border: pw.Border.all(
                  color: const PdfColor.fromInt(0xFFCBD5E1),
                  width: 0.85,
                ),
              ),
              child: pw.Row(
                children: [
                  // TOTAL PAGADO
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'TOTAL PAGADO',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF15803D),
                            letterSpacing: 0.5,
                          ),
                        ),
                        pw.SizedBox(height: 2.5),
                        pw.Text(
                          'Bs. ${totalRecaudado.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF16A34A),
                          ),
                        ),
                        pw.SizedBox(height: 1),
                        pw.Text(
                          '$cantPagados conductores',
                          style: const pw.TextStyle(
                            fontSize: 7,
                            color: PdfColor.fromInt(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: 1,
                    height: 32,
                    color: const PdfColor.fromInt(0xFFCBD5E1),
                  ),
                  // TOTAL QUE FALTA
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'TOTAL QUE FALTA',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFFDC2626),
                            letterSpacing: 0.5,
                          ),
                        ),
                        pw.SizedBox(height: 2.5),
                        pw.Text(
                          'Bs. ${totalFalta.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFFDC2626),
                          ),
                        ),
                        pw.SizedBox(height: 1),
                        pw.Text(
                          '$cantDeben pendientes',
                          style: const pw.TextStyle(
                            fontSize: 7,
                            color: PdfColor.fromInt(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.Container(
                    width: 1,
                    height: 32,
                    color: const PdfColor.fromInt(0xFFCBD5E1),
                  ),
                  // TOTAL GENERAL
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'TOTAL GENERAL',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF0F3A78),
                            letterSpacing: 0.5,
                          ),
                        ),
                        pw.SizedBox(height: 2.5),
                        pw.Text(
                          'Bs. ${totalMeta.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF0F3A78),
                          ),
                        ),
                        pw.SizedBox(height: 1),
                        pw.Text(
                          '$totalConductores conductores',
                          style: const pw.TextStyle(
                            fontSize: 7,
                            color: PdfColor.fromInt(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 9),

            // 3. CUOTA A EVALUAR Y MONTO FIJADO
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF9FBFE),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
                border: pw.Border.all(
                  color: const PdfColor.fromInt(0xFF93C5FD),
                  width: 0.9,
                ),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Cuota a Evaluar:',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF0F2B5B),
                          ),
                        ),
                        pw.SizedBox(height: 1),
                        pw.Text(
                          tituloCuota,
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF0F2B5B),
                          ),
                        ),
                        if (beneficiario != null &&
                            beneficiario.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Row(
                            children: [
                              pw.SizedBox(
                                width: 68,
                                child: pw.Text(
                                  'Beneficiario:',
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColor.fromInt(0xFF475569),
                                  ),
                                ),
                              ),
                              pw.Text(
                                beneficiario,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: const PdfColor.fromInt(0xFF0F2B5B),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (modalidad != null && modalidad.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Row(
                            children: [
                              pw.SizedBox(
                                width: 68,
                                child: pw.Text(
                                  'Modalidad:',
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColor.fromInt(0xFF475569),
                                  ),
                                ),
                              ),
                              pw.Text(
                                modalidad,
                                style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: modalidad.toLowerCase() == 'voluntaria'
                                      ? const PdfColor.fromInt(0xFF15803D)
                                      : const PdfColor.fromInt(0xFF1D4ED8),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (motivoTexto != null &&
                            motivoTexto.isNotEmpty &&
                            motivoTexto != 'Apoyo económico solidario') ...[
                          pw.SizedBox(height: 2),
                          pw.Row(
                            children: [
                              pw.SizedBox(
                                width: 68,
                                child: pw.Text(
                                  'Motivo:',
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColor.fromInt(0xFF475569),
                                  ),
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  motivoTexto,
                                  style: const pw.TextStyle(
                                    fontSize: 8,
                                    color: PdfColor.fromInt(0xFF1E293B),
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.Container(
                    width: 1,
                    height: 44,
                    color: const PdfColor.fromInt(0xFF93C5FD),
                    margin: const pw.EdgeInsets.symmetric(horizontal: 14),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      pw.Text(
                        'Monto Fijado:',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF0F2B5B),
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'Bs. ${montoSugerido.toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF0B3C73),
                        ),
                      ),
                      pw.Text(
                        'c/u',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: PdfColor.fromInt(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // 3. TABLA DE CONDUCTORES (POR MESES SI ES CANASTÓN, O TABLA ÚNICA SI ES APOYO ECONÓMICO)
            if (esCanaston)
              ..._buildTablasCanastonPorMes(
                conductores: conductores,
                fechasUnicas: fechasUnicas,
                listaCronograma: listaCronograma,
              )
            else
              pw.Table(
                border: pw.TableBorder.all(
                  color: const PdfColor.fromInt(0xFFCBD5E1),
                  width: 0.6,
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(24),
                  1: const pw.FlexColumnWidth(3.4),
                  2: const pw.FlexColumnWidth(1.4),
                  3: const pw.FlexColumnWidth(1.4),
                  4: const pw.FlexColumnWidth(1.6),
                  5: const pw.FlexColumnWidth(1.6),
                  6: const pw.FlexColumnWidth(1.3),
                },
                children: [
                  // Encabezados (se repiten en cada hoja automáticamente)
                  pw.TableRow(
                    repeat: true,
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF0F3A78),
                    ),
                    children: [
                      _buildCell('#', isHeader: true, align: pw.TextAlign.center),
                      _buildCell('Conductor', isHeader: true, align: pw.TextAlign.left),
                      _buildCell('C.I.', isHeader: true, align: pw.TextAlign.center),
                      _buildCell('Monto (Bs.)', isHeader: true, align: pw.TextAlign.center),
                      _buildCell('Estado', isHeader: true, align: pw.TextAlign.center),
                      _buildCell('Fecha de Pago', isHeader: true, align: pw.TextAlign.center),
                      _buildCell('Método', isHeader: true, align: pw.TextAlign.center),
                    ],
                  ),
                  // Filas de cada conductor
                  ...conductores.asMap().entries.map((entry) {
                    final i = entry.key;
                    final c = entry.value;
                    final nombre =
                        c['conductor_nombre']?.toString() ?? 'Conductor';
                    final ci = c['conductor_ci']?.toString() ?? '';
                    final falta =
                        (c['monto_falta'] as num?)?.toDouble() ?? 0.0;
                    final total =
                        (c['monto_total'] as num?)?.toDouble() ?? montoSugerido;
                    final alDia = falta <= 0.001;
                    final fechaPago = c['fecha_pago']?.toString();
                    final metodoPago = c['metodo_pago']?.toString();
                    final bgFila = i % 2 == 1
                        ? const PdfColor.fromInt(0xFFF8FAFC)
                        : PdfColors.white;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: bgFila),
                      children: [
                        _buildCell('${i + 1}', align: pw.TextAlign.center, esBold: true),
                        _buildCell(nombre, esBold: false, align: pw.TextAlign.left),
                        _buildCell(ci.isNotEmpty ? ci : '--', align: pw.TextAlign.center),
                        _buildCell(total.toStringAsFixed(2), align: pw.TextAlign.center),
                        // Badge Estado
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          child: pw.Center(
                            child: pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: pw.BoxDecoration(
                                color: alDia
                                    ? const PdfColor.fromInt(0xFFDCFCE7)
                                    : const PdfColor.fromInt(0xFFFEE2E2),
                                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                              ),
                              child: pw.Text(
                                alDia ? 'PAGADO' : 'NO PAGADO',
                                style: pw.TextStyle(
                                  fontSize: 6.8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: alDia
                                      ? const PdfColor.fromInt(0xFF15803D)
                                      : const PdfColor.fromInt(0xFFDC2626),
                                ),
                              ),
                            ),
                          ),
                        ),
                        _buildCell(
                          alDia ? _formatearFechaDdMmYyyy(fechaPago) : '--',
                          align: pw.TextAlign.center,
                          color: alDia ? null : const PdfColor.fromInt(0xFF94A3B8),
                        ),
                        _buildCell(
                          alDia ? _formatearMetodo(metodoPago) : '--',
                          align: pw.TextAlign.center,
                          color: alDia ? null : const PdfColor.fromInt(0xFF94A3B8),
                        ),
                      ],
                    );
                  }),
                  // Fila de Totales
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFFDCEAFB),
                    ),
                    children: [
                      _buildCell('TOTALES:', esBold: true, align: pw.TextAlign.left, color: const PdfColor.fromInt(0xFF0F2B5B)),
                      _buildCell('$totalConductores CONDUCTORES', esBold: true, align: pw.TextAlign.left, color: const PdfColor.fromInt(0xFF0F2B5B)),
                      _buildCell('', align: pw.TextAlign.center),
                      _buildCell('Bs. ${totalMeta.toStringAsFixed(2)}', esBold: true, align: pw.TextAlign.center, color: const PdfColor.fromInt(0xFF0F2B5B)),
                      _buildCell('', align: pw.TextAlign.center),
                      _buildCell('$cantPagados PAGOS', esBold: true, align: pw.TextAlign.center, color: const PdfColor.fromInt(0xFF1D4ED8)),
                      _buildCell('$cantDeben NO PAGOS', esBold: true, align: pw.TextAlign.center, color: const PdfColor.fromInt(0xFFDC2626)),
                    ],
                  ),
                ],
              ),
            // 4. FIRMAS (BLOQUE INDIVISIBLE QUE SE ADAPTA A LA HOJA CORRESPONDIENTE)
            pw.SizedBox(height: 24),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
              children: [
                pw.Column(
                  children: [
                    pw.Container(
                      width: 150,
                      height: 1,
                      color: const PdfColor.fromInt(0xFF0F3A78),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Secretaría de Hacienda',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF0F2B5B),
                      ),
                    ),
                    pw.Text(
                      'Control Económico',
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfColor.fromInt(0xFF475569),
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  children: [
                    pw.Container(
                      width: 150,
                      height: 1,
                      color: const PdfColor.fromInt(0xFF0F3A78),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Secretaría General',
                      style: pw.TextStyle(
                        fontSize: 8.5,
                        fontWeight: pw.FontWeight.bold,
                        color: const PdfColor.fromInt(0xFF0F2B5B),
                      ),
                    ),
                    pw.Text(
                      'Sindicato Continental Trufi',
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfColor.fromInt(0xFF475569),
                      ),
                    ),
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

  /// Construye una tabla separada por cada MES para cuotas periódicas (Canastón),
  /// sin columna C.I., con columnas de fechas de ese mes y estilo de planilla Excel.
  static List<pw.Widget> _buildTablasCanastonPorMes({
    required List<Map<String, dynamic>> conductores,
    required List<String> fechasUnicas,
    required List<Map<String, dynamic>> listaCronograma,
  }) {
    // Mapa rápido: idConductor -> (fecha -> montoPagado)
    final Map<String, Map<String, double>> pagosMatriz = {};
    for (final row in listaCronograma) {
      final idCond = row['id_conductor']?.toString() ?? '';
      final fecha = row['fecha_programada']?.toString().trim() ?? '';
      final pagado = (row['monto_pagado'] as num?)?.toDouble() ?? 0.0;
      if (idCond.isEmpty || fecha.isEmpty) continue;
      pagosMatriz.putIfAbsent(idCond, () => {});
      pagosMatriz[idCond]![fecha] = (pagosMatriz[idCond]![fecha] ?? 0.0) + pagado;
    }

    // Agrupar fechas por mes (YYYY-MM) manteniendo orden cronológico
    final Map<String, List<String>> fechasPorMes = {};
    for (final f in fechasUnicas) {
      final claveMes = f.length >= 7 ? f.substring(0, 7) : 'GENERAL';
      fechasPorMes.putIfAbsent(claveMes, () => []).add(f);
    }

    // Paletas de colores mensuales inspiradas en su planilla Excel
    const paletasMes = <Map<String, int>>[
      {
        'banner': 0xFF1E3A8A,
        'headerFecha': 0xFFB8CCE4,
        'celdaPagada': 0xFFDCE6F1,
        'textoHeader': 0xFF0F172A,
      },
      {
        'banner': 0xFF9A3412,
        'headerFecha': 0xFFFABF8F,
        'celdaPagada': 0xFFFDE9D9,
        'textoHeader': 0xFF0F172A,
      },
      {
        'banner': 0xFF3F6212,
        'headerFecha': 0xFFC4D79B,
        'celdaPagada': 0xFFEBF1DE,
        'textoHeader': 0xFF0F172A,
      },
      {
        'banner': 0xFF881337,
        'headerFecha': 0xFFE6B8B7,
        'celdaPagada': 0xFFF2DCDB,
        'textoHeader': 0xFF0F172A,
      },
      {
        'banner': 0xFF155E75,
        'headerFecha': 0xFF92CDDC,
        'celdaPagada': 0xFFDAEEF3,
        'textoHeader': 0xFF0F172A,
      },
      {
        'banner': 0xFF581C87,
        'headerFecha': 0xFFCCC0DA,
        'celdaPagada': 0xFFE4DFEC,
        'textoHeader': 0xFF0F172A,
      },
      {
        'banner': 0xFF854D0E,
        'headerFecha': 0xFFFFF2CC,
        'celdaPagada': 0xFFFEF9E7,
        'textoHeader': 0xFF0F172A,
      },
    ];

    final widgets = <pw.Widget>[];
    int mesIdx = 0;

    for (final entryMes in fechasPorMes.entries) {
      final claveMes = entryMes.key;
      final todasFechasMes = entryMes.value;
      final paleta = paletasMes[mesIdx % paletasMes.length];
      final colorBanner = PdfColor.fromInt(paleta['banner']!);
      final colorHeaderFecha = PdfColor.fromInt(paleta['headerFecha']!);
      final colorCeldaPagada = PdfColor.fromInt(paleta['celdaPagada']!);
      final colorTextoHeader = PdfColor.fromInt(paleta['textoHeader']!);
      mesIdx++;

      // Si un mismo mes tuviera más de 7 fechas, lo dividimos en bloques de máximo 7 columnas
      const maxColsPorTabla = 7;
      for (int offset = 0; offset < todasFechasMes.length; offset += maxColsPorTabla) {
        final fin = (offset + maxColsPorTabla < todasFechasMes.length)
            ? offset + maxColsPorTabla
            : todasFechasMes.length;
        final fechasBloque = todasFechasMes.sublist(offset, fin);
        final sufijoBloque = todasFechasMes.length > maxColsPorTabla
            ? ' (Parte ${(offset ~/ maxColsPorTabla) + 1})'
            : '';

        if (widgets.isNotEmpty) {
          widgets.add(pw.SizedBox(height: 14));
        }

        // Encabezado del Mes
        widgets.add(
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: pw.BoxDecoration(
              color: colorBanner,
              borderRadius: const pw.BorderRadius.vertical(
                top: pw.Radius.circular(6),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'MES: ${_nombreMesAnio(claveMes)}$sufijoBloque',
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.Text(
                  '${fechasBloque.length} ${fechasBloque.length == 1 ? 'fecha programada' : 'fechas programadas'}',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
        );

        // Configurar anchos de columnas: NRO | NOMBRES Y APELLIDOS | Fechas... | TOTAL MES
        final colWidths = <int, pw.TableColumnWidth>{
          0: const pw.FixedColumnWidth(24),
          1: const pw.FlexColumnWidth(3.1),
        };
        for (int fIdx = 0; fIdx < fechasBloque.length; fIdx++) {
          colWidths[2 + fIdx] = const pw.FlexColumnWidth(1.1);
        }
        colWidths[2 + fechasBloque.length] = const pw.FlexColumnWidth(1.25);

        // Sumatorias por columna de fecha para la fila inferior
        final totalesPorFecha = List<double>.filled(fechasBloque.length, 0.0);
        double totalGeneralMes = 0.0;

        final filasConductores = conductores.asMap().entries.map((entryCond) {
          final idx = entryCond.key;
          final c = entryCond.value;
          final idCond = c['id_conductor']?.toString() ?? '';
          final nombre = (c['conductor_nombre']?.toString() ?? 'Conductor').toUpperCase();
          final bgBase = idx % 2 == 1
              ? const PdfColor.fromInt(0xFFF8FAFC)
              : PdfColors.white;

          double totalConductorMes = 0.0;
          final celdasFechas = <pw.Widget>[];

          for (int fIdx = 0; fIdx < fechasBloque.length; fIdx++) {
            final fStr = fechasBloque[fIdx];
            final pagado = pagosMatriz[idCond]?[fStr] ?? 0.0;
            if (pagado > 0.001) {
              totalesPorFecha[fIdx] += pagado;
              totalConductorMes += pagado;
              totalGeneralMes += pagado;
              celdasFechas.add(
                pw.Container(
                  color: colorCeldaPagada,
                  padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 5),
                  alignment: pw.Alignment.center,
                  child: pw.Text(
                    _formatearMontoCorto(pagado),
                    textAlign: pw.TextAlign.center,
                    style: pw.TextStyle(
                      fontSize: 7.8,
                      fontWeight: pw.FontWeight.bold,
                      color: const PdfColor.fromInt(0xFF0F172A),
                    ),
                  ),
                ),
              );
            } else {
              // Celda en blanco si no pagó (igual que en su Excel)
              celdasFechas.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 5),
                  child: pw.Text(''),
                ),
              );
            }
          }

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bgBase),
            children: [
              _buildCell('${idx + 1}', align: pw.TextAlign.center, esBold: true),
              _buildCell(nombre, align: pw.TextAlign.left, esBold: false),
              ...celdasFechas,
              _buildCell(
                totalConductorMes > 0.001
                    ? 'Bs. ${_formatearMontoCorto(totalConductorMes)}'
                    : '',
                align: pw.TextAlign.center,
                esBold: true,
                color: const PdfColor.fromInt(0xFF0F2B5B),
              ),
            ],
          );
        }).toList();

        widgets.add(
          pw.Table(
            border: pw.TableBorder.all(
              color: const PdfColor.fromInt(0xFF64748B),
              width: 0.6,
            ),
            columnWidths: colWidths,
            children: [
              // Fila de encabezados (se repite automáticamente si pasa a otra hoja)
              pw.TableRow(
                repeat: true,
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF0F3A78),
                ),
                children: [
                  _buildCell('NRO', isHeader: true, align: pw.TextAlign.center),
                  _buildCell('NOMBRES Y APELLIDOS', isHeader: true, align: pw.TextAlign.left),
                  ...fechasBloque.map(
                    (fStr) => pw.Container(
                      color: colorHeaderFecha,
                      padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 5),
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        _etiquetaDiaDeMes(fStr),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          fontSize: 7.2,
                          fontWeight: pw.FontWeight.bold,
                          color: colorTextoHeader,
                        ),
                      ),
                    ),
                  ),
                  _buildCell('TOTAL MES', isHeader: true, align: pw.TextAlign.center),
                ],
              ),
              ...filasConductores,
              // Fila de Totales del Mes
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFDCEAFB),
                ),
                children: [
                  _buildCell('', align: pw.TextAlign.center),
                  _buildCell(
                    'TOTALES DEL MES:',
                    esBold: true,
                    align: pw.TextAlign.right,
                    color: const PdfColor.fromInt(0xFF0F2B5B),
                  ),
                  ...totalesPorFecha.map(
                    (sumaFecha) => _buildCell(
                      sumaFecha > 0.001 ? _formatearMontoCorto(sumaFecha) : '0',
                      esBold: true,
                      align: pw.TextAlign.center,
                      color: const PdfColor.fromInt(0xFF0F2B5B),
                    ),
                  ),
                  _buildCell(
                    'Bs. ${_formatearMontoCorto(totalGeneralMes)}',
                    esBold: true,
                    align: pw.TextAlign.center,
                    color: const PdfColor.fromInt(0xFF15803D),
                  ),
                ],
              ),
            ],
          ),
        );
      }
    }

    return widgets;
  }

  static String _nombreMesAnio(String claveYm) {
    const mesesCompletos = [
      'ENERO',
      'FEBRERO',
      'MARZO',
      'ABRIL',
      'MAYO',
      'JUNIO',
      'JULIO',
      'AGOSTO',
      'SEPTIEMBRE',
      'OCTUBRE',
      'NOVIEMBRE',
      'DICIEMBRE',
    ];
    final partes = claveYm.split('-');
    if (partes.length >= 2) {
      final anio = partes[0];
      final mes = int.tryParse(partes[1]) ?? 1;
      if (mes >= 1 && mes <= 12) {
        return '${mesesCompletos[mes - 1]} $anio';
      }
    }
    return claveYm.toUpperCase();
  }

  static String _etiquetaDiaDeMes(String fechaIso) {
    const mesesCortos = [
      'ENE',
      'FEB',
      'MAR',
      'ABR',
      'MAY',
      'JUN',
      'JUL',
      'AGOS',
      'SEPT',
      'OCT',
      'NOV',
      'DIC',
    ];
    try {
      final d = DateTime.parse(fechaIso.trim());
      return '${d.day} DE ${mesesCortos[d.month - 1]}';
    } catch (_) {
      return fechaIso;
    }
  }

  static String _formatearMontoCorto(double valor) {
    if ((valor - valor.roundToDouble()).abs() < 0.005) {
      return valor.round().toString();
    }
    return valor.toStringAsFixed(2);
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

  static String _formatearFechaDdMmYyyy(dynamic f) {
    if (f == null || f.toString().trim().isEmpty) return '--';
    try {
      final d = DateTime.parse(f.toString().trim());
      return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    } catch (_) {
      return f.toString();
    }
  }

  static String _formatearMetodo(dynamic m) {
    if (m == null || m.toString().trim().isEmpty) return '--';
    final str = m.toString().trim().toLowerCase();
    if (str == 'qr') return 'QR';
    if (str == 'efectivo') return 'Efectivo';
    if (str == 'transferencia') return 'Transf.';
    return m.toString();
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
    String? idTipoCuota,
    String? categoria,
  }) async {
    List<Map<String, dynamic>>? cuotasCronograma;
    if (idTipoCuota != null && idTipoCuota.trim().isNotEmpty) {
      try {
        cuotasCronograma = await EconomiaRepo.instance
            .obtenerMatrizCronogramaPorCuota(idTipoCuota);
      } catch (_) {
        cuotasCronograma = null;
      }
    }

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
      categoria: categoria,
      cuotasCronograma: cuotasCronograma,
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

