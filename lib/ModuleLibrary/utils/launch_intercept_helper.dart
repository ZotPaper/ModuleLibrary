import 'dart:async';

/// LaunchPage 启动拦截回调
/// [onProceed] 调用此方法继续 LaunchPage 的正常流程
/// [onDeny] 调用此方法中断 LaunchPage 的流程，由外部自行处理
typedef LaunchInterceptCallback = void Function(
  void Function() onProceed,
  void Function() onDeny,
);

class LaunchInterceptHelper {
  // 单例模式
  static final LaunchInterceptHelper instance = LaunchInterceptHelper._internal();
  LaunchInterceptHelper._internal();

  // 拦截回调
  LaunchInterceptCallback? _interceptor;

  /// 设置拦截器
  /// 
  /// 在 LaunchPage 启动时会检查是否有拦截器：
  /// - 如果没有设置拦截器，LaunchPage 正常执行
  /// - 如果设置了拦截器，会调用拦截器并等待外部决定
  ///   - 外部调用 onProceed()：LaunchPage 继续正常流程
  ///   - 外部调用 onDeny()：LaunchPage 中断，由外部自行处理后续逻辑
  void setInterceptor(LaunchInterceptCallback interceptor) {
    _interceptor = interceptor;
  }

  /// 清除拦截器
  void clearInterceptor() {
    _interceptor = null;
  }

  /// 检查是否有拦截器
  bool hasInterceptor() {
    return _interceptor != null;
  }

  /// 执行拦截逻辑
  /// 
  /// 返回 Future<bool>:
  /// - true: 没有拦截器 或 拦截器调用了 onProceed，继续执行 LaunchPage
  /// - false: 拦截器调用了 onDeny，中断 LaunchPage 流程
  Future<bool> intercept() async {
    if (_interceptor == null) {
      return true; // 没有拦截器，继续执行
    }

    final completer = Completer<bool>();

    _interceptor!(
      () {
        if (!completer.isCompleted) {
          completer.complete(true); // onProceed: 继续执行
        }
      },
      () {
        if (!completer.isCompleted) {
          completer.complete(false); // onDeny: 中断执行
        }
      },
    );

    return completer.future;
  }
}
