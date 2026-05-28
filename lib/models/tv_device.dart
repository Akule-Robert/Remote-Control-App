class TvDevice {
  final String id;
  final String name;
  final String ip;
  final int port;
  final String model;
  bool isConnected;
  bool isPaired;

  TvDevice({
    required this.id,
    required this.name,
    required this.ip,
    this.port = 6466,
    this.model = 'Android TV',
    this.isConnected = false,
    this.isPaired = false,
  });

  TvDevice copyWith({bool? isConnected, bool? isPaired}) => TvDevice(
    id: id, name: name, ip: ip, port: port, model: model,
    isConnected: isConnected ?? this.isConnected,
    isPaired: isPaired ?? this.isPaired,
  );
}
