import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:rh_os/domain/entidades/vaga.dart';
import 'package:rh_os/domain/repositorios/i_vaga_repositorio.dart';

class VagaRepositorioFirestore implements IVagaRepositorio {
  // Colecao principal de vagas.
  final _col = FirebaseFirestore.instance.collection('vagas');

  // Converte entidade para mapa persistido.
  Map<String, dynamic> _toFirestore(Vaga v) {
    final map = v.toMap();
    map.remove('id');
    map.remove('idStr');
    return map;
  }

  // Converte documento para entidade com idStr.
  Vaga _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final now = DateTime.now().toIso8601String();
    final data = <String, dynamic>{
      'criado_em': now,
      'atualizado_em': now,
      ...doc.data() ?? {},
      'idStr': doc.id,
    };
    return Vaga.fromMap(data);
  }

  @override
  // D7: try/catch — salvar não crasha o app.
  Future<int> salvar(Vaga vaga) async {
    try {
      if (vaga.idStr != null) {
        await _col.doc(vaga.idStr).set(_toFirestore(vaga));
      } else {
        await _col.add(_toFirestore(vaga));
      }
    } catch (e) {
      debugPrint('[VagaRepo] salvar: $e');
    }
    return 0;
  }

  @override
  // D7: try/catch — atualizar não crasha o app.
  Future<int> atualizar(Vaga vaga) async {
    try {
      if (vaga.idStr != null) {
        await _col.doc(vaga.idStr).set(_toFirestore(vaga));
      }
    } catch (e) {
      debugPrint('[VagaRepo] atualizar: $e');
    }
    return 0;
  }

  @override
  // D2: stub int ignorado — usar deletarPorIdStr(String).
  Future<int> deletar(int id) async {
    debugPrint('[VagaRepo] deletar(int) ignorado — usar deletarPorIdStr');
    return 0;
  }

  @override
  // D2: stub int ignorado — usar buscarPorIdStr(String).
  Future<Vaga?> buscarPorId(int id) async {
    debugPrint('[VagaRepo] buscarPorId(int) ignorado — usar buscarPorIdStr');
    return null;
  }

  @override
  // D7: try/catch — listarTodas retorna [] em caso de erro Firestore.
  Future<List<Vaga>> listarTodas() async {
    try {
      final snap = await _col.get();
      return snap.docs.map(_fromDoc).toList();
    } catch (e) {
      debugPrint('[VagaRepo] listarTodas: $e');
      return [];
    }
  }

  @override
  // D7: try/catch — listarPorStatus retorna [] em caso de erro.
  Future<List<Vaga>> listarPorStatus(String status) async {
    try {
      final snap = await _col.where('status', isEqualTo: status).get();
      return snap.docs.map(_fromDoc).toList();
    } catch (e) {
      debugPrint('[VagaRepo] listarPorStatus: $e');
      return [];
    }
  }

  @override
  Future<List<Vaga>> buscarPorTitulo(String termo) async => [];

  @override
  // D7: try/catch — contarPorStatus retorna 0 em caso de erro.
  Future<int> contarPorStatus(String status) async {
    try {
      final snap = await _col.where('status', isEqualTo: status).get();
      return snap.docs.length;
    } catch (e) {
      debugPrint('[VagaRepo] contarPorStatus: $e');
      return 0;
    }
  }

  @override
  // D2: stub int ignorado — usar atualizarStatusStr(String, String).
  Future<void> atualizarStatus(int id, String status) async {
    debugPrint(
        '[VagaRepo] atualizarStatus(int) ignorado — usar atualizarStatusStr');
  }

  // D7: try/catch — buscarPorIdStr retorna null em caso de erro.
  @override
  Future<Vaga?> buscarPorIdStr(String idStr) async {
    try {
      final doc = await _col.doc(idStr).get();
      if (!doc.exists) return null;
      return _fromDoc(doc);
    } catch (e) {
      debugPrint('[VagaRepo] buscarPorIdStr: $e');
      return null;
    }
  }

  // D7: try/catch — deletarPorIdStr não crasha o app.
  @override
  Future<void> deletarPorIdStr(String idStr) async {
    try {
      await _col.doc(idStr).delete();
    } catch (e) {
      debugPrint('[VagaRepo] deletarPorIdStr: $e');
    }
  }

  // D7: try/catch — atualizarStatusStr não crasha o app.
  @override
  Future<void> atualizarStatusStr(String idStr, String status) async {
    try {
      await _col.doc(idStr).update({'status': status});
    } catch (e) {
      debugPrint('[VagaRepo] atualizarStatusStr: $e');
    }
  }
}
