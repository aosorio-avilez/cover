enum ExitCode {
  success(code: 0, message: 'success'),
  fail(code: 1, message: 'fail'),
  usage(code: 64, message: 'usage'),
  osFile(code: 72, message: 'osFile');

  const ExitCode({
    required this.code,
    required this.message,
  });

  final int code;
  final String message;
}
