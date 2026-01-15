# CommonAPI + vsomeip 통합 계획 (Fresh Start)

## 🎯 목표
- **순수 CommonAPI + SOME/IP** 방식으로 ECU 간 통신 구현
- **공식 가이드 완전 준수**: [CommonAPI C++ SomeIP in 10 minutes](https://github.com/COVESA/capicxx-someip-tools/wiki/CommonAPI-C---SomeIP-in-10-minutes)
- ## 📚 참고 자료

### **공식 문서**
- **메인 가이드**: [CommonAPI C++ SomeIP in 10 minutes](https://github.com/COVESA/capicxx-someip-tools/wiki/CommonAPI-C---SomeIP-in-10-minutes)
- **CommonAPI 공식 홈페이지**: https://covesa.github.io/capicxx-core-tools/

### **소스 코드 저장소 (사용한 버전)**
- **vsomeip v3.5.8**: https://github.com/COVESA/vsomeip/tree/3.5.8
- **CommonAPI Core Runtime v3.2.4**: https://github.com/COVESA/capicxx-core-runtime/tree/3.2.4  
- **CommonAPI SomeIP Runtime v3.2.4**: https://github.com/COVESA/capicxx-someip-runtime/tree/3.2.4

### **코드 생성기 다운로드 (v3.2.0.1)**
- **Core Generator**: [commonapi_core_generator.zip](https://github.com/COVESA/capicxx-core-tools/releases/download/3.2.0.1/commonapi_core_generator.zip)
- **SomeIP Generator**: [commonapi_someip_generator.zip](https://github.com/COVESA/capicxx-someip-tools/releases/download/3.2.0.1/commonapi_someip_generator.zip)

### **사용된 시스템 환경**
- **OS**: Ubuntu 22.04 LTS
- **Java**: OpenJDK 11.0.24
- **CMake**: 3.22.1
- **Git**: 2.34.1
- **Boost**: 1.74.0 (시스템 패키지) ECU 통신** 시뮬레이션 (vsomeip 직접 사용 NO)

## 📋 단계별 계획

### Phase 1: 환경 설정 (Prerequisites) ✅
- [x] **Step 1-2**: 기본 준비사항 확인
  - [x] Java 11 Runtime 설치 확인
  - [x] CMake >= 3.13 설치 확인  
  - [x] Git 설치 확인

**사용한 명령어:**
```bash
# 환경 확인
java -version        # OpenJDK 11.0.24
cmake --version      # CMake 3.22.1
git --version        # Git 2.34.1
```

### Phase 2: 런타임 라이브러리 빌드 ✅
- [x] **Step 3**: CommonAPI SOME/IP Runtime Library 빌드
  - [x] vsomeip 다운로드 및 빌드 (v3.5.8)
  - [x] CommonAPI Core Runtime 빌드 (v3.2.4)
  - [x] CommonAPI SomeIP Runtime 빌드 (v3.2.4)
  - [x] Boost 라이브러리 설치 확인 (v1.74.0)

**사용한 명령어:**

**2.1 vsomeip 빌드:**
```bash
# GitHub에서 다운로드
git clone https://github.com/COVESA/vsomeip.git
cd vsomeip
git checkout 3.5.8

# 빌드 및 설치
cmake -Bbuild -DCMAKE_INSTALL_PREFIX=../install_folder \
  -DENABLE_SIGNAL_HANDLING=1 -DDIAGNOSIS_ADDRESS=0x10 .
cmake --build build --target install
```

**2.2 CommonAPI Core Runtime 빌드:**
```bash
# GitHub에서 다운로드
git clone https://github.com/COVESA/capicxx-core-runtime.git
cd capicxx-core-runtime
git checkout 3.2.4

# 빌드 및 설치
cmake -Bbuild -DCMAKE_INSTALL_PREFIX=../install_folder .
cmake --build build --target install
```

**2.3 CommonAPI SomeIP Runtime 빌드:**
```bash
# GitHub에서 다운로드
git clone https://github.com/COVESA/capicxx-someip-runtime.git
cd capicxx-someip-runtime
git checkout 3.2.4

# 빌드 및 설치
cmake -Bbuild -DCMAKE_INSTALL_PREFIX=../install_folder \
  -DCMAKE_PREFIX_PATH=../install_folder \
  -DUSE_INSTALLED_COMMONAPI=OFF .
cmake --build build --target install
```

**GitHub 저장소:**
- vsomeip: https://github.com/COVESA/vsomeip
- CommonAPI Core: https://github.com/COVESA/capicxx-core-runtime  
- CommonAPI SomeIP: https://github.com/COVESA/capicxx-someip-runtime

### Phase 3: 코드 생성 도구 설치
- [ ] **Step 4**: 코드 생성기 다운로드
### Phase 3: Code Generators ✅
- [x] Download CommonAPI Core Generator from official COVESA releases
- [x] Download CommonAPI SomeIP Generator from official COVESA releases  
- [x] Set executable permissions and verify generators work
- [x] **CONFIRMED**: Core Generator works with `.fidl` + `-sk` option
- [x] **CONFIRMED**: SomeIP Generator works with `.fdepl` files

**⚠️ CRITICAL: 압축 해제 방법 (파일 충돌 방지)**

**❌ 잘못된 방법 (파일 덮어쓰기 발생):**
```bash
cd commonapi-generators
unzip commonapi_core_generator.zip     # 루트에 해제
unzip commonapi_someip_generator.zip   # 같은 루트에 해제 → 충돌!
```

**✅ 올바른 방법 (별도 디렉토리 분리):**
```bash
mkdir commonapi_core && cd commonapi_core
unzip ../commonapi_core_generator.zip   # 별도 폴더에 해제

cd ../
mkdir commonapi_someip && cd commonapi_someip  
unzip ../commonapi_someip_generator.zip # 별도 폴더에 해제
```

**문제 원인:** 두 ZIP 파일 모두 `commonapi-core-generator-linux-x86_64` 파일명 포함
- Core ZIP의 파일: 진짜 Core Generator
- SomeIP ZIP의 파일: 실제로는 SomeIP Generator (같은 파일명)
- 결과: 나중에 압축 해제한 파일이 이전 파일 덮어씀

**검증 완료:**
- MD5 해시 테스트로 파일 덮어쓰기 100% 확인
- 별도 디렉토리 분리 시 정상 작동

**사용한 명령어:**

**3.1 생성기 다운로드:**
```bash
# 디렉토리 생성
mkdir -p /home/leo/SEA-ME/DES_Head-Unit/deps/commonapi-generators
cd /home/leo/SEA-ME/DES_Head-Unit/deps/commonapi-generators

# Core Generator 다운로드
wget https://github.com/COVESA/capicxx-core-tools/releases/download/3.2.0.1/commonapi_core_generator.zip

# SomeIP Generator 다운로드  
wget https://github.com/COVESA/capicxx-someip-tools/releases/download/3.2.0.1/commonapi_someip_generator.zip
```

**3.2 별도 디렉토리 압축 해제:**
```bash
# Core Generator 압축 해제
mkdir commonapi_core && cd commonapi_core
unzip ../commonapi_core_generator.zip
chmod +x commonapi-core-generator-linux-x86_64

# SomeIP Generator 압축 해제
cd ../
mkdir commonapi_someip && cd commonapi_someip  
unzip ../commonapi_someip_generator.zip
chmod +x commonapi-someip-generator-linux-x86_64
```

**3.3 생성기 테스트:**
```bash
# Core Generator 테스트 (.fidl + -sk 옵션)
./commonapi_core/commonapi-core-generator-linux-x86_64 -d . -sk HelloWorld.fidl

# SomeIP Generator 테스트 (.fdepl 파일)
./commonapi_someip/commonapi-someip-generator-linux-x86_64 -d . HelloWorld.fdepl
```

**GitHub 릴리즈:**
- Core Generator: https://github.com/COVESA/capicxx-core-tools/releases/tag/3.2.0.1
- SomeIP Generator: https://github.com/COVESA/capicxx-someip-tools/releases/tag/3.2.0.1

**Generator Locations:**
- CommonAPI Core: `/home/leo/SEA-ME/DES_Head-Unit/deps/commonapi-generators/commonapi_core/commonapi-core-generator-linux-x86_64`
- CommonAPI SomeIP: `/home/leo/SEA-ME/DES_Head-Unit/deps/commonapi-generators/commonapi_someip/commonapi-someip-generator-linux-x86_64`


### Phase 4: HelloWorld 튜토리얼 완전 가이드 ✅
**참고:** [CommonAPI C++ SomeIP in 10 minutes - Step 4](https://github.com/COVESA/capicxx-someip-tools/wiki/CommonAPI-C---SomeIP-in-10-minutes#step-4-write-the-franca-file-and-generate-code)

**📁 최종 디렉토리 구조:**
```
/home/leo/SEA-ME/DES_Head-Unit/tutorial/HelloWorld/
├── HelloWorld.fidl                    # 인터페이스 정의
├── HelloWorld.fdepl                   # SomeIP 배포 설정
├── HelloWorldService.cpp              # 서비스 애플리케이션
├── HelloWorldClient.cpp               # 클라이언트 애플리케이션
├── HelloWorldStubImpl.hpp/.cpp        # 서비스 구현
├── CMakeLists.txt                     # 빌드 설정
├── commonapi4someip.ini               # CommonAPI 설정
├── vsomeip.json                       # vsomeip 설정
├── src-gen/                           # 생성된 코드
│   ├── core/v1/commonapi/             # Core 생성 파일들
│   └── someip/v1/commonapi/           # SomeIP 생성 파일들
└── build/                             # 빌드 디렉토리
    ├── HelloWorldService              # 빌드된 서비스 실행파일
    └── HelloWorldClient               # 빌드된 클라이언트 실행파일
```

## **Step-by-Step 완전 가이드** 🎯

### **STEP 1: 작업 디렉토리 생성**
```bash
mkdir -p /home/leo/SEA-ME/DES_Head-Unit/tutorial/HelloWorld
cd /home/leo/SEA-ME/DES_Head-Unit/tutorial/HelloWorld
mkdir -p src-gen/core src-gen/someip
```

### **STEP 2: 인터페이스 정의 파일 작성**

**HelloWorld.fidl 생성:**
```fidl
package commonapi

interface HelloWorld {
    version { major 1 minor 0 }
    
    method sayHello {
        in {
            String name
        }
        out {
            String message
        }
    }
}
```

**HelloWorld.fdepl 생성:**
```
import "platform:/plugin/org.genivi.commonapi.someip/deployment/CommonAPI-SOMEIP_deployment_spec.fdepl"
import "HelloWorld.fidl"

define org.genivi.commonapi.someip.deployment for interface commonapi.HelloWorld {
    SomeIpServiceID = 4660

    method sayHello {
        SomeIpMethodID = 30000
    }
}

define org.genivi.commonapi.someip.deployment for provider as Service: commonapi.HelloWorld {
    instance commonapi.HelloWorld {
        SomeIpInstanceID = 22136
    }
}
```

### **STEP 3: 코드 생성**
```bash
# 현재 위치: /home/leo/SEA-ME/DES_Head-Unit/tutorial/HelloWorld

# Core Generator 실행
/home/leo/SEA-ME/DES_Head-Unit/deps/commonapi-generators/commonapi_core/commonapi-core-generator-linux-x86_64 \
  -d src-gen/core -sk HelloWorld.fidl

# SomeIP Generator 실행
/home/leo/SEA-ME/DES_Head-Unit/deps/commonapi-generators/commonapi_someip/commonapi-someip-generator-linux-x86_64 \
  -d src-gen/someip HelloWorld.fdepl
```

**생성되는 파일들 확인:**
```bash
find src-gen -name "*.hpp" -o -name "*.cpp"
# 예상 출력:
# src-gen/core/v1/commonapi/HelloWorld.hpp
# src-gen/core/v1/commonapi/HelloWorldProxy.hpp
# src-gen/core/v1/commonapi/HelloWorldStub.hpp
# src-gen/someip/v1/commonapi/HelloWorldSomeIPProxy.hpp/.cpp
# src-gen/someip/v1/commonapi/HelloWorldSomeIPStubAdapter.hpp/.cpp
# src-gen/someip/v1/commonapi/HelloWorldSomeIPDeployment.hpp/.cpp
```

### **STEP 4: 애플리케이션 구현**

**HelloWorldStubImpl.hpp 작성:**
```cpp
#ifndef HELLOWORLDSTUBIMPL_H_
#define HELLOWORLDSTUBIMPL_H_

#include <CommonAPI/CommonAPI.hpp>
#include <v1/commonapi/HelloWorldStubDefault.hpp>

class HelloWorldStubImpl : public v1_0::commonapi::HelloWorldStubDefault {
public:
    HelloWorldStubImpl();
    virtual ~HelloWorldStubImpl();
    virtual void sayHello(const std::shared_ptr<CommonAPI::ClientId> _client, 
                          std::string _name, 
                          sayHelloReply_t _return);
};

#endif /* HELLOWORLDSTUBIMPL_H_ */
```

**HelloWorldStubImpl.cpp 작성:**
```cpp
#include "HelloWorldStubImpl.hpp"
#include <iostream>

HelloWorldStubImpl::HelloWorldStubImpl() { }
HelloWorldStubImpl::~HelloWorldStubImpl() { }

void HelloWorldStubImpl::sayHello(const std::shared_ptr<CommonAPI::ClientId> _client, 
                                  std::string _name, 
                                  sayHelloReply_t _reply) {
    std::stringstream messageStream;
    messageStream << "Hello " << _name << "!";
    std::cout << "sayHello('" << _name << "'): '" << messageStream.str() << "'\n";
    
    _reply(messageStream.str());
}
```

**HelloWorldService.cpp 작성:**
```cpp
#include <iostream>
#include <thread>
#include <CommonAPI/CommonAPI.hpp>
#include "HelloWorldStubImpl.hpp"

int main() {
    CommonAPI::Runtime::setProperty("LogContext", "E01S");
    CommonAPI::Runtime::setProperty("LogApplication", "E01S");
    CommonAPI::Runtime::setProperty("LibraryBase", "HelloWorld");

    std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();

    std::string domain = "local";
    std::string instance = "commonapi.HelloWorld";
    std::string connection = "service-sample";

    std::shared_ptr<HelloWorldStubImpl> myService = std::make_shared<HelloWorldStubImpl>();
    bool successfullyRegistered = runtime->registerService(domain, instance, myService, connection);

    if (!successfullyRegistered) {
        std::cout << "Failed to register service!" << std::endl;
        return -1;
    }

    std::cout << "Successfully Registered Service!" << std::endl;

    while (true) {
        std::cout << "Waiting for calls... (Abort with CTRL+C)" << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(30));
    }

    return 0;
}
```

**HelloWorldClient.cpp 작성:**
```cpp
#include <iostream>
#include <string>
#include <unistd.h>
#include <CommonAPI/CommonAPI.hpp>
#include <v1/commonapi/HelloWorldProxy.hpp>

using namespace v1_0::commonapi;

int main() {
    CommonAPI::Runtime::setProperty("LogContext", "E01C");
    CommonAPI::Runtime::setProperty("LogApplication", "E01C");
    CommonAPI::Runtime::setProperty("LibraryBase", "HelloWorld");

    std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();

    std::string domain = "local";
    std::string instance = "commonapi.HelloWorld";
    std::string connection = "client-sample";

    std::shared_ptr<HelloWorldProxyDefault> myProxy = runtime->buildProxy<HelloWorldProxy>(domain, instance, connection);

    std::cout << "Checking availability!" << std::endl;
    while (!myProxy->isAvailable())
        usleep(10);
    std::cout << "Available..." << std::endl;

    CommonAPI::CallStatus callStatus;
    std::string returnMessage;

    myProxy->sayHello("Bob", callStatus, returnMessage);

    if (callStatus != CommonAPI::CallStatus::SUCCESS) {
        std::cout << "Remote call failed!\n";
        return -1;
    }

    std::cout << "Got message: '" << returnMessage << "'\n";
    
    return 0;
}
```

### **STEP 5: 빌드 설정**

**CMakeLists.txt 작성:**
```cmake
cmake_minimum_required(VERSION 3.10)
project(HelloWorld VERSION 1.0)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find packages
find_package(CommonAPI REQUIRED)
find_package(CommonAPI-SomeIP REQUIRED)
find_package(vsomeip3 REQUIRED)

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/src-gen/core
    ${CMAKE_CURRENT_SOURCE_DIR}/src-gen/someip
    ${CMAKE_CURRENT_SOURCE_DIR}/v1/commonapi
)

# Add generated source files
set(GENERATED_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src-gen/someip/v1/commonapi/HelloWorldSomeIPProxy.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src-gen/someip/v1/commonapi/HelloWorldSomeIPStubAdapter.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src-gen/someip/v1/commonapi/HelloWorldSomeIPDeployment.cpp
)

# HelloWorld Service
add_executable(HelloWorldService
    HelloWorldService.cpp
    HelloWorldStubImpl.cpp
    ${GENERATED_SOURCES}
)

target_link_libraries(HelloWorldService
    CommonAPI
    CommonAPI-SomeIP
    vsomeip3
)

# HelloWorld Client
add_executable(HelloWorldClient
    HelloWorldClient.cpp
    ${GENERATED_SOURCES}
)

target_link_libraries(HelloWorldClient
    CommonAPI
    CommonAPI-SomeIP
    vsomeip3
)
```

**commonapi4someip.ini 작성:**
```ini
[logging]
console=true
file=
dlt=false
level=info

[binding:commonapi_someip]
config=/home/leo/SEA-ME/DES_Head-Unit/tutorial/HelloWorld/vsomeip.json

[address_translation]
local:commonapi.HelloWorld:v1_0:commonapi.HelloWorld=1234.5678
```

**vsomeip.json 작성:**
```json
{
    "unicast" : "127.0.0.1",
    "logging" :
    {
        "level" : "debug",
        "console" : "true",
        "file" : { "enable" : "false", "path" : "/tmp/vsomeip.log" },
        "dlt" : "false"
    },
    "applications" :
    [
        {
            "name" : "service-sample",
            "id" : "0x1277"
        },
        {
            "name" : "client-sample",
            "id" : "0x1344"
        }
    ],
    "services" :
    [
        {
            "service" : "0x1234",
            "instance" : "0x5678",
            "unreliable" : "30509"
        }
    ],
    "routing" : "service-sample",
    "service-discovery" :
    {
        "enable" : "true",
        "multicast" : "224.0.0.1",
        "port" : "30490",
        "protocol" : "udp",
        "initial_delay_min" : "10",
        "initial_delay_max" : "100",
        "repetitions_base_delay" : "200",
        "repetitions_max" : "3",
        "ttl" : "3",
        "cyclic_offer_delay" : "2000",
        "request_response_delay" : "1500"
    }
}
```

### **STEP 6: 빌드 및 실행**

**빌드:**
```bash
mkdir -p build && cd build
cmake .. && make -j$(nproc)

# 성공 시 생성되는 파일들:
# ./HelloWorldService
# ./HelloWorldClient
```

**실행 테스트:**
```bash
# 환경변수 설정
export COMMONAPI_CONFIG=/home/leo/SEA-ME/DES_Head-Unit/tutorial/HelloWorld/commonapi4someip.ini
export VSOMEIP_CONFIGURATION=/home/leo/SEA-ME/DES_Head-Unit/tutorial/HelloWorld/vsomeip.json

# 터미널 1: 서비스 실행
./HelloWorldService

# 터미널 2: 클라이언트 실행 (서비스 실행 후)
./HelloWorldClient
```

### **⚠️ 알려진 이슈: 주소 매핑 문제**
**현상:**
```
[CAPI][ERROR] Cannot determine SOME/IP address data for CommonAPI address "local:commonapi.HelloWorld:v1_0:commonapi.HelloWorld"
```

**원인:** CommonAPI ↔ SomeIP 주소 매핑 설정 복잡성
**상태:** 빌드는 성공하나 런타임 주소 매핑 추가 연구 필요

**Phase 4 성과:**
✅ 전체 빌드 체인 검증 완료
✅ 생성기 정상 작동 확인  
✅ 실제 프로젝트 적용 기반 마련

### Phase 5: Vehicle Control 실제 구현
- [ ] **실제 프로젝트 적용**
  - [ ] VehicleControl.fidl 설계
  - [ ] VehicleControl.fdepl 배포 설정
  - [ ] Mock ECU 서비스 구현
  - [ ] Head Unit 클라이언트 구현

## 🔧 기술 스택 결정
- **통신**: CommonAPI + SOME/IP (vsomeip 기반)
- **코드 생성**: 공식 생성기 사용 (Core + SomeIP)
- **언어**: C++ 17
- **빌드**: CMake
- **UI**: Qt5/QML (기존 앱 통합)

## � 문제 해결 과정 (중요)

### **문제**: Core Generator가 .fidl 파일을 인식하지 못함
- **증상**: `.fidl` 파일 입력 시 "The file extension should be .fdepl" 오류
- **원인**: 파일 덮어쓰기로 인한 생성기 혼재

### **근본 원인 분석:**
1. **파일명 충돌**: 두 ZIP 모두 `commonapi-core-generator-linux-x86_64` 포함
2. **덮어쓰기**: 같은 폴더 압축 해제 시 나중 파일이 이전 파일 덮어씀  
3. **검증**: MD5 해시값 동일 확인 (`b22a99bdb6e102bf8e5ba8e6b233f85f`)

**검증에 사용한 명령어:**
```bash
# 문제 재현 테스트
mkdir test_mixed_extraction && cd test_mixed_extraction
unzip commonapi_core_generator.zip      # 첫 번째 압축 해제
unzip commonapi_someip_generator.zip    # 두 번째 압축 해제 (덮어쓰기)

# 파일 충돌 확인
ls -la commonapi-*-generator-linux-x86_64  # 크기 동일 확인
md5sum commonapi-*-generator-linux-x86_64  # 해시값 동일 확인

# 실제 테스트
./commonapi-core-generator-linux-x86_64 -d . -sk HelloWorld.fidl
# 결과: NullPointerException (SomeIP Generator가 .fidl 처리 불가)
```

### **해결책**: 별도 디렉토리 분리 압축 해제

### **교훈**: 공식 생성기라도 파일명 충돌 가능성 있음

## �📚 참고 자료
- **메인 가이드**: [CommonAPI SomeIP 10분](https://github.com/COVESA/capicxx-someip-tools/wiki/CommonAPI-C---SomeIP-in-10-minutes)
- **생성기 다운로드**: 
  - [Core Generator](https://github.com/COVESA/capicxx-core-tools/releases/download/3.2.0.1/commonapi_core_generator.zip)
  - [SomeIP Generator](https://github.com/COVESA/capicxx-someip-tools/releases/download/3.2.0.1/commonapi_someip_generator.zip)
- **vsomeip**: [GitHub](https://github.com/GENIVI/vsomeip)
- **CommonAPI Core**: [GitHub](https://github.com/GENIVI/capicxx-core-runtime)
- **CommonAPI SomeIP**: [GitHub](https://github.com/GENIVI/capicxx-someip-runtime)
