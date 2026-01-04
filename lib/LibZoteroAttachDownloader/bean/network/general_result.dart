// 假设的返回类型定义
class CustomResult<T> {
  final T? value;
  final String? error;
  final int? httpCode;

  const CustomResult({this.value, this.error, this.httpCode});

  bool get isSuccess => error == null;
  bool get isFailure => error != null;

  factory CustomResult.success(T? value) {
    return CustomResultSuccess(value);
  }

  factory CustomResult.error(String error, {int? httpCode}) {
    return CustomResultError(error, httpCode: httpCode);
  }
}

class CustomResultSuccess<T> extends CustomResult<T> {
  CustomResultSuccess(T? value) : super(value: value);
}

class CustomResultError<T> extends CustomResult<T> {
  CustomResultError(String error, {super.httpCode}) : super(error: error);
}

