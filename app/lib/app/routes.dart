/// 路由路径的唯一来源。页面之间跳转一律经这里拼地址，不手写字符串。
abstract final class Routes {
  static const shelf = '/shelf';
  static const history = '/history';
  static const mine = '/mine';
  static const login = '/login';
  static const player = '/player';
  static const offline = '/mine/offline';

  static const addSeries = '/shelf/add';

  static String series(String id) => '/shelf/series/$id';

  static String browse(String path) =>
      Uri(path: '/shelf/browse', queryParameters: {'path': path}).toString();

  static String help([String? section]) => Uri(
        path: '/help',
        queryParameters: section == null ? null : {'section': section},
      ).toString();
}
