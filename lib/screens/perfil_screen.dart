import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../core/permisos.dart';
import '../models/usuario_model.dart';
import '../widgets/app_background.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/info_row.dart';
import '../widgets/custom_list_tile.dart';
import '../services/sesion_service.dart';
import 'usuarios_screen.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el usuario autenticado actualmente desde SQLite
    final usuario = Usuario.currentUser;

    final nombre = usuario?.nombre ?? SesionService.instance.nombre ?? 'Sin sesión activa';
    final rol = usuario?.rol ?? SesionService.instance.rol ?? 'Invitado';
    final correo = usuario?.gmail ?? SesionService.instance.gmail;
    final ci = usuario?.ci ?? SesionService.instance.ci;
    final trufi = usuario?.numeroTrufi;
    final estado = usuario?.estado ?? 'Activo';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(title: 'Mi perfil'),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Encabezado del Perfil
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.iconBgBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                      ),
                      child: const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, color: AppColors.primaryBlue, size: 30),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre, 
                            style: const TextStyle(
                              color: AppColors.primaryDark, 
                              fontSize: 18, 
                              fontWeight: FontWeight.w800
                            )
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rol.toUpperCase(), 
                            style: const TextStyle(
                              color: AppColors.textGray, 
                              fontSize: 14, 
                              fontWeight: FontWeight.w500
                            )
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Bloque de Información
              GlassCard(
                child: Column(
                  children: [
                    if (correo != null && correo.isNotEmpty) ...[
                      InfoRow(icon: Icons.email_outlined, label: 'Correo', value: correo),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(height: 1, color: AppColors.dividerColor),
                      ),
                    ],
                    if (ci != null && ci.isNotEmpty) ...[
                      InfoRow(icon: Icons.badge_outlined, label: 'CI', value: ci),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(height: 1, color: AppColors.dividerColor),
                      ),
                    ],
                    if (trufi != null && trufi.isNotEmpty) ...[
                      InfoRow(icon: Icons.directions_bus_outlined, label: 'Trufi / Unidad', value: trufi),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(height: 1, color: AppColors.dividerColor),
                      ),
                    ],
                    InfoRow(
                      icon: Icons.check_circle_outline, 
                      label: 'Estado', 
                      value: estado,
                      iconColor: estado.toLowerCase() == 'activo' ? AppColors.success : AppColors.danger,
                      iconBackgroundColor: estado.toLowerCase() == 'activo' ? AppColors.iconBgGreen : AppColors.dangerBg,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Opciones de Configuración
              GlassCard(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    CustomListTile(
                      icon: Icons.history, 
                      title: 'Historial de asistencia', 
                      onTap: () {}
                    ),
                    const Divider(height: 1, color: AppColors.dividerColor, indent: 56, endIndent: 16),
                    CustomListTile(
                      icon: Icons.warning_amber_rounded, 
                      title: 'Historial de sanciones', 
                      onTap: () {}
                    ),
                    const Divider(height: 1, color: AppColors.dividerColor, indent: 56, endIndent: 16),
                    CustomListTile(
                      icon: Icons.account_balance_wallet_outlined, 
                      title: 'Historial de cuotas', 
                      onTap: () {}
                    ),
                    const Divider(height: 1, color: AppColors.dividerColor, indent: 56, endIndent: 16),
                    if (Permisos.puedeVer(rol, Permisos.moduloUsuarios)) ...[
                      CustomListTile(
                        icon: Icons.manage_accounts_outlined, 
                        title: 'Gestión de usuarios', 
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const UsuariosScreen()));
                        }
                      ),
                      const Divider(height: 1, color: AppColors.dividerColor, indent: 56, endIndent: 16),
                    ],
                    CustomListTile(
                      icon: Icons.settings_outlined, 
                      title: 'Configuración', 
                      onTap: () {}
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Botón de Cerrar Sesión
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => SesionService.instance.cerrarSesion(context),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text('Cerrar sesión'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
