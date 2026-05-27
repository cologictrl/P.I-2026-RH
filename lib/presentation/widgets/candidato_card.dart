// ============================================================
// candidato_card.dart
// Responsabilidade: Card de listagem rapida de candidato
// Camada: presentation
// ============================================================

import 'package:flutter/material.dart';
import 'package:rh_os/core/constantes/app_strings.dart';
import 'package:rh_os/core/tema/app_cores.dart';
import 'package:rh_os/core/tema/app_estilos.dart';
import 'package:rh_os/core/utils/formatadores.dart';
import 'package:rh_os/core/utils/validadores.dart';

class CandidatoCard extends StatelessWidget {
  // Construtor do card de candidato
  const CandidatoCard({
    super.key,
    required this.nome,
    this.dataNascimento,
    this.sexo,
    this.rua,
    this.numero,
    this.bairro,
    this.cidade,
    this.estado,
    this.email,
    this.telefone,
    this.aoExcluir,
    this.aoEditar,
    this.aoVerCompleto,
  });

  final String nome;
  final String? dataNascimento;
  final String? sexo;
  final String? rua;
  final String? numero;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final String? email;
  final String? telefone;
  final VoidCallback? aoExcluir;
  final VoidCallback? aoEditar;
  final VoidCallback? aoVerCompleto;

  @override
  Widget build(BuildContext context) {
    // Calcula dados derivados para exibir no card
    final idade = Formatadores.calcularIdade(dataNascimento);
    final endRua =
        [rua, numero].where((e) => e != null && e.isNotEmpty).join(', ');
    final endCidade =
        [cidade, estado].where((e) => e != null && e.isNotEmpty).join('/');
    final telefoneFmt = Validadores.normalizarTelefone(telefone);

    return Card(
      color: AppCores.fundoCard,
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$nome — ${AppStrings.infosRapidas}',
              style: AppEstilos.headerSecao,
            ),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Coluna(
                      titulo: 'Info pessoal',
                      linhas: [
                        if (dataNascimento != null &&
                            dataNascimento!.isNotEmpty)
                          'Nasc: ${Formatadores.dataBr(dataNascimento)}',
                        if (idade > 0) 'Idade: $idade anos',
                        if (sexo != null && sexo!.isNotEmpty) 'Sexo: $sexo',
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFE0E0E0)),
                  Expanded(
                    child: _Coluna(
                      titulo: 'Endereço',
                      linhas: [
                        if (endRua.isNotEmpty) endRua,
                        if (bairro != null && bairro!.isNotEmpty) bairro!,
                        if (endCidade.isNotEmpty) endCidade,
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1, color: Color(0xFFE0E0E0)),
                  Expanded(
                    child: _Coluna(
                      titulo: 'Contato',
                      linhas: [
                        if (email != null && email!.isNotEmpty) email!,
                        if (telefoneFmt != null && telefoneFmt.isNotEmpty)
                          telefoneFmt,
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: aoExcluir,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppCores.cta,
                      side: const BorderSide(color: AppCores.cta),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      textStyle: const TextStyle(fontSize: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(AppStrings.excluirCurriculo),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton(
                    onPressed: aoEditar,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppCores.primaria,
                      side: const BorderSide(color: AppCores.primaria),
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      textStyle: const TextStyle(fontSize: 11),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(AppStrings.editarCurriculo),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: ElevatedButton(
                    onPressed: aoVerCompleto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppCores.primaria,
                      foregroundColor: AppCores.textoClaro,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      textStyle: const TextStyle(fontSize: 11),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(AppStrings.verCurriculoCompleto),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Coluna extends StatelessWidget {
  // Construtor da coluna interna do card
  const _Coluna({required this.titulo, required this.linhas});

  final String titulo;
  final List<String> linhas;

  @override
  Widget build(BuildContext context) {
    // Renderiza uma coluna de informacoes com lista de linhas
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppCores.primaria,
            ),
          ),
          const SizedBox(height: 4),
          ...linhas.map(
            (l) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                l,
                style: AppEstilos.labelCampo,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
          if (linhas.isEmpty) const Text('—', style: AppEstilos.labelCampo),
        ],
      ),
    );
  }
}
