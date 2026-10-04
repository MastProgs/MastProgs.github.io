// 브라우저가 아닌 환경(VM 테스트)의 HostPlatform: 메모리 구현을 쓴다.
import 'host_platform.dart';

HostPlatform createPlatform() => MemoryHostPlatform();
