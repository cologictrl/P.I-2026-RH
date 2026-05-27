// E5: merge concilia listas sem sobrescrever dados existentes.
import 'package:flutter/foundation.dart';
import 'package:rh_os/domain/entidades/candidato.dart';
import 'package:rh_os/domain/entidades/experiencia.dart';
import 'package:rh_os/domain/entidades/formacao.dart';
import 'package:rh_os/domain/entidades/habilidade.dart';
import 'package:rh_os/domain/entidades/idioma.dart';
import 'package:rh_os/domain/repositorios/i_candidato_repositorio.dart';

class MergeCandidato {
  final ICandidatoRepositorio _repo;
  MergeCandidato(this._repo);

  Future<void> executar(
    Candidato existente,
    Candidato novo, {
    List<Map<String, dynamic>>? experiencias,
    List<Map<String, dynamic>>? formacoes,
    List<String>? habilidades,
    List<Map<String, dynamic>>? idiomas,
  }) async {
    // Atualiza campos simples: novo prevalece sobre existente quando não-nulo.
    final atualizado = existente.copyWith(
      nome: novo.nome.isNotEmpty ? novo.nome : existente.nome,
      telefone: novo.telefone ?? existente.telefone,
      logradouro: novo.logradouro ?? existente.logradouro,
      numero: novo.numero ?? existente.numero,
      bairro: novo.bairro ?? existente.bairro,
      cidade: novo.cidade ?? existente.cidade,
      estado: novo.estado ?? existente.estado,
      cep: novo.cep ?? existente.cep,
      resumo: novo.resumo ?? existente.resumo,
    );
    final atualizadoComId = atualizado.copyWith(idStr: existente.idStr);

    try {
      // E5.1: carregar listas existentes do Firestore.
      List<Habilidade> habExistentes = [];
      List<Idioma> idiomasExistentes = [];
      List<Experiencia> expExistentes = [];
      List<Formacao> formExistentes = [];

      if (existente.idStr != null) {
        final results = await Future.wait([
          _repo.listarHabilidadesStr(existente.idStr!),
          _repo.listarIdiomasStr(existente.idStr!),
          _repo.listarExperienciasStr(existente.idStr!),
          _repo.listarFormacoesStr(existente.idStr!),
        ]);
        habExistentes = (results[0] as List).cast<Habilidade>();
        idiomasExistentes = (results[1] as List).cast<Idioma>();
        expExistentes = (results[2] as List).cast<Experiencia>();
        formExistentes = (results[3] as List).cast<Formacao>();
        debugPrint('[MergeCandidato] existentes — '
            'hab:${habExistentes.length} '
            'idi:${idiomasExistentes.length} '
            'exp:${expExistentes.length} '
            'form:${formExistentes.length}');
      }

      // E5.2: mesclar habilidades (case-insensitive, sem duplicatas).
      final habNovas = List<String>.from(habilidades ?? []);
      for (final e in habExistentes) {
        if (!habNovas.any((h) => h.toLowerCase() == e.nome.toLowerCase())) {
          habNovas.add(e.nome);
        }
      }

      // E5.3: mesclar idiomas (por nome, case-insensitive).
      final idiomasNovos = List<Map<String, dynamic>>.from(idiomas ?? []);
      for (final e in idiomasExistentes) {
        if (!idiomasNovos.any((i) =>
            i['nome']?.toString().toLowerCase() == e.nome.toLowerCase())) {
          idiomasNovos.add({'nome': e.nome, 'nivel': e.nivel});
        }
      }

      // E5.4: mesclar experiências (por cargo+empresa, case-insensitive).
      final expNovas = List<Map<String, dynamic>>.from(experiencias ?? []);
      for (final e in expExistentes) {
        final cargoNorm = e.cargo.toLowerCase();
        final empresaNorm = e.empresa.toLowerCase();
        if (!expNovas.any((ex) =>
            ex['cargo']?.toString().toLowerCase() == cargoNorm &&
            ex['empresa']?.toString().toLowerCase() == empresaNorm)) {
          expNovas.add({
            'cargo': e.cargo,
            'empresa': e.empresa,
            'descricao': e.descricao,
            'dataInicio': e.dataInicio,
            'dataFim': e.dataFim,
            'atual': e.atual,
          });
        }
      }

      // E5.5: mesclar formações (por instituicao+curso, case-insensitive).
      final formNovas = List<Map<String, dynamic>>.from(formacoes ?? []);
      for (final e in formExistentes) {
        final instNorm = e.instituicao.toLowerCase();
        final cursoNorm = e.curso.toLowerCase();
        if (!formNovas.any((f) =>
            f['instituicao']?.toString().toLowerCase() == instNorm &&
            f['curso']?.toString().toLowerCase() == cursoNorm)) {
          formNovas.add({
            'instituicao': e.instituicao,
            'curso': e.curso,
            'nivel': e.nivel,
            'dataInicio': e.dataInicio,
            'dataFim': e.dataFim,
            'emAndamento': e.emAndamento,
          });
        }
      }

      debugPrint('[MergeCandidato] mesclado — '
          'hab:${habNovas.length} '
          'idi:${idiomasNovos.length} '
          'exp:${expNovas.length} '
          'form:${formNovas.length}');

      // E5.6: salvar com listas mescladas.
      await _repo.salvarCompleto(
        atualizadoComId,
        experiencias: expNovas,
        formacoes: formNovas,
        habilidades: habNovas,
        idiomas: idiomasNovos,
      );
      debugPrint('[MergeCandidato] ${existente.idStr} mesclado com sucesso.');
      return;
    } catch (e) {
      debugPrint('[MergeCandidato] Erro ao mesclar listas: $e');
    }

    // Fallback: salva campos simples sem merge de listas.
    await _repo.salvar(atualizadoComId);
    debugPrint('[MergeCandidato] ${existente.idStr} atualizado (fallback).');
  }
}
