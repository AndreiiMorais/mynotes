///serve para filtrar a lista e passar apenas as notes do determinado usuário
///funciona recebendo um teste e somente vai retornar se o teste for true
extension Filter<T> on Stream<List<T>> {
  Stream<List<T>> filter(bool Function(T) where) =>
      map((items) => items.where(where).toList());
}
