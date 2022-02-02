<template>
  <v-app>
    <v-main>
      <v-container>
        
        <h1>서버 아키텍쳐 설계 및 리펙토링 (위메이드플러스)</h1>
        <br>

        <v-btn
          class="ma-2"
          dark
          @click="showDialog(14)"
        >
          채팅 서버 구현
        </v-btn>
        <v-dialog
          max-width="800"
          v-model="dialogsDataList[14].flag"
        >
          <my-dialog
            header-title="채팅 서버 구현"
            @submit="submitDialog(14)"
          >
            <template v-slot:body>
              MQTT 기술을 활용하여 Intagram / Facebook 와 같은 채팅 서버를 구현하였습니다. Broker 서버를 통해 채팅 메세지를 주고 받고, Redis 에 다양한 채팅 대화 및 방 생성 정보를 저장하며 활용하였습니다. 
            </template>
          </my-dialog>
        </v-dialog>
        
        <v-btn
          class="ma-2"
          dark
          @click="showDialog(13)"
        >
          DBJob 프로세스 구현
        </v-btn>
        <v-dialog
          max-width="800"
          v-model="dialogsDataList[13].flag"
        >
          <my-dialog
            header-title="DBJob 프로세스"
            @submit="submitDialog(13)"
          >
            <template v-slot:body>
              TypeORM 을 활용하여, Save / Update / Delete / Increase / Decrease 같은 DB에 요청해야하는 다중 쿼리문과 Redis 에 요청해야하는 다양한 request 들을 한번의 트랜잭션으로 묶어 요청할 수 있도록 코드로 구현하였습니다. 
            </template>
          </my-dialog>
          <v-btn
            dark
            href="https://github.com/MastProgs/custom-codes/blob/main/DBJob.ts"
            target="_blank"
            >
            <v-icon>mdi-github</v-icon>
            DBJob 구현 코드 보기
          </v-btn>
        </v-dialog>
        
        <v-btn
          class="ma-2"
          dark
          @click="showDialog(12)"
        >
          Pager 프로세스 구현
        </v-btn>
        <v-dialog
          max-width="800"
          v-model="dialogsDataList[12].flag"
        >
          <my-dialog
            header-title="Pager 프로세스"
            @submit="submitDialog(12)"
          >
            <template v-slot:body>
              SNS 에서 스크롤링 및 페이지 형태로 데이터를 가져오는 기법인 Pagination 라이브러리를 훨씬 더 사용하기 쉽게 랩핑한 클래스입니다. TypeORM 의 Select 구문을 Pager 에 초기화 값으로 넣어주고, DB에서 읽은 책갈피 위치에 대한 Hash 값을 같이 넣고 실행시키면, 다음 위치의 Hash 값과 다음 data limit size 만큼 값을 반환하는 클래스 입니다.
            </template>
          </my-dialog>
          <v-btn
            dark
            href="https://github.com/MastProgs/custom-codes/blob/main/Pager.ts"
            target="_blank"
            >
            <v-icon>mdi-github</v-icon>
            Pager 구현 코드 보기
          </v-btn>
        </v-dialog>
        
        <br><br>
        <v-divider/>
        <br>

        <h1>개발망 전용 툴 구현 (조이시티)</h1>
        <br>

        <v-btn
          class="ma-2"
          dark
          @click="showDialog(11)"
        >
          개발망 클라 런처
        </v-btn>
        <v-dialog
          max-width="800"
          v-model="dialogsDataList[11].flag"
        >
          <my-dialog
            header-title="개발망 클라 런처"
            @submit="submitDialog(11)"
          >
            <template v-slot:body>
              각 국가 버전별 실행 명령인자 값이 다르고, id pw ip port 등등 여러 정보를 매 실행마다 수동으로 입력하여 클라를 실행해야하는 시스템이라 불편했었습니다. 자동화 작업으로 버튼 몇 개만 누르면 입맛에 맞는 실행 명령을 입력하여 개발망 클라이언트를 구동시킬 수 있는 런처 툴을 제작하여 나눠드렸고, 개발 시간 단축에 힘을 보탰습니다.
            </template>
          </my-dialog>
        </v-dialog>
        
        <v-btn
          class="ma-2"
          dark
          @click="showDialog(10)"
        >
          개발망 아이템 지급 툴
        </v-btn>
        <v-dialog
          max-width="800"
          v-model="dialogsDataList[10].flag"
        >
          <my-dialog
            header-title="개발망 아이템 지급 툴"
            @submit="submitDialog(10)"
          >
            <template v-slot:body>
              개발 과정 중에 필요한 아이템이나 캐릭터 셋팅에 필요한 부분들을 매번 서버 프로그래머에 요청하는 프로세스로 작업을 하기에 비효율적이었습니다. 자동화 작업으로 필요한 버튼 몇 개만 누르면 아이템 지급이나 캐릭터 상태에 대한 셋팅을 진행할 수 있도록 툴을 제작하여 나눠드렸고, 개발 시간 단축에 힘을 보탰습니다.
            </template>
          </my-dialog>
        </v-dialog>
        
        <br><br>
        <v-divider/>
        <br>

        <h1>컨텐츠 및 시스템 구현 내용 (모아이, 한빛)</h1>
        <br>

        <v-btn
          class="ma-2"
          dark
          @click="showDialog(0)"
        >
          업적
        </v-btn>
        <v-dialog
          max-width="800"
          v-model="dialogsDataList[0].flag"
        >
          <my-dialog
            header-title="업적"
            @submit="submitDialog(0)"
          >
            <template v-slot:body>
              <v-row>
                <v-img class="ml-4 mr-4" src="../assets/process_achv1.png" width="80%"/>
                <v-img class="ml-4 mr-4" src="../assets/process_achv2.png" width="80%"/>
              </v-row>
              <v-textarea
                filled
                auto-grow
                readonly
                value="특정 행동에 대한 업적 진행도를 올려주거나, 달성한 업적에 대해 보상을 지급하는 컨텐츠를 구현하였었습니다. DB부하를 줄이기 위해 LazyStore 라는 기능을 따로 구현하여 1분마다 관련 정보를 저장할 수 있도록 처리하였습니다."
              />
            </template>
          </my-dialog>
        </v-dialog>

  
        <v-btn
          class="ma-2"
          dark
          @click="showDialog(1)"
        >
          SubLoader
        </v-btn>
        <v-dialog
          max-width="800"
          v-model="dialogsDataList[1].flag"
        >
          <my-dialog
            header-title="SubLoader"
            @submit="submitDialog(1)"
          >
            <template v-slot:body>
              <v-row>
                <v-img class="ml-4 mr-4" src="../assets/process_subloader.png" width="80%"/>
              </v-row>
              <v-textarea
                filled
                auto-grow
                readonly
                value="처음 플레이어가 서버에 접속 할 때, 플레이어와 관련한 정보를 모두 다 불러와야 하는데, 처음부터 불필요한 정보까지 모두 불러올 필요가 없으므로, 데이터가 필요한 순간에 즉시 최초 한 번만 DB로 부터 정보를 받아오는 시스템을 구현하였었습니다. (우편, 이벤트 정보 등등)"
              />
            </template>
          </my-dialog>
        </v-dialog>

        <v-btn
          class="ma-2"
          dark
          @click="showDialog(2)"
        >
          AWS GameLift Flexmatch
        </v-btn>
        <v-dialog
          max-width="800"
          v-model="dialogsDataList[2].flag"
        >
          <my-dialog
            header-title="AWS GameLift Flexmatch"
            @submit="submitDialog(2)"
          >
            <template v-slot:body>
              <v-row>
                <v-img class="ml-4 mr-4" src="../assets/AWSgameliftFlexmatch.png" width="80%"/>
              </v-row>
              <v-textarea
                filled
                auto-grow
                readonly
                value="클라이언트가 로비 서버에서 매치메이킹을 신청하면 이를 웹 서버로 전달하고, 웹 서버는 AWS에 기능을 요청하여 관련 유니크한 티켓을 받아 매치메이킹에 대한 정보를 중개하는 역할을 구현하였습니다. 매칭이 이루어 진다면 GameLift 내의 임의 데디서버에 방을 생성하여 주고, 연결에 필요한 정보들을 파싱하여 각 클라이언트에게 정보를 건네주는 순서로 진행되었습니다. AWS SNS 같은 기능을 활용하여 반복적인 loop 부분을, 매칭 되었을 시점에만 클라이언트에게 알려주는 형태로 만들고 싶었으나, AWS SNS 서비스 이용에 대한 추가 발생 요금을 회사측이 허용해주질 않았기에 아쉽게도 구현해보지는 못했습니다."
              />
            </template>
          </my-dialog>
        </v-dialog>

        <br><br>
        <v-divider/>
        <br>
        <h1>기타 구현 내용</h1>
        <br>

        <v-btn
          class="ma-2"
          dark
          @click="showDialog(3)"
        >
          기억의 돌
        </v-btn>
        <v-dialog
          max-width="800"
          v-model="dialogsDataList[3].flag"
        >
          <my-dialog
            header-title="기억의 돌"
            @submit="submitDialog(3)"
          >
            <template v-slot:body>
              현재 위치를 기억하고, 기억의 돌을 소모하여 특정 위치로 이동하는 컨텐츠, 좌표를 즉시 DB에 저장하고, 아이템 사용 시 해당 저장 위치로 캐릭터 이동하는 기능.
            </template>
          </my-dialog>
        </v-dialog>
        
        <v-btn
          class="ma-2"
          dark
          @click="showDialog(4)"
        >
          칭호
        </v-btn>
        <v-dialog
          max-width="800"
          v-model="dialogsDataList[4].flag"
        >
          <my-dialog
            header-title="칭호"
            @submit="submitDialog(4)"
          >
            <template v-slot:body>
              칭호 지급 및 조건부 칭호 기능 구현, 칭호와 연동된 능력치 지급 기능 구현. 조건부 칭호의 경우, 매 시즌마다 초기화 되며 다음 시즌 시 랭킹 별 보상으로 지급.
            </template>
          </my-dialog>
        </v-dialog>
        
        <v-btn
          class="ma-2"
          dark
          @click="showDialog(5)"
        >
          출석 이벤트
        </v-btn>
        <v-dialog
          max-width="800"
          v-model="dialogsDataList[5].flag"
        >
          <my-dialog
            header-title="출석 이벤트"
            @submit="submitDialog(5)"
          >
            <template v-slot:body>
              매일 출석에 따라 스크립트에 입력된 보상 지급기능 구현 및 관련 정보 DB 기록.
            </template>
          </my-dialog>
        </v-dialog>
        
        <v-btn
          class="ma-2"
          dark
          @click="showDialog(6)"
        >
          누적 접속 보상 이벤트
        </v-btn>
        <v-dialog
          max-width="800"
          v-model="dialogsDataList[6].flag"
        >
          <my-dialog
            header-title="누적 접속 보상 이벤트"
            @submit="submitDialog(6)"
          >
            <template v-slot:body>
              접속한 시간에 비례하여 스크립트에 입력된 보상 지급 기능 구현 및 관련 정보 DB 기록. 타이머를 통해 보상을 받을 수 있는 접속 시간이 되면 클라에 알림 발송.
            </template>
          </my-dialog>
        </v-dialog>
        
        <v-btn
          class="ma-2"
          dark
          @click="showDialog(7)"
        >
          오늘의 활동
        </v-btn>
        <v-dialog
          max-width="800"
          v-model="dialogsDataList[7].flag"
        >
          <my-dialog
            header-title="오늘의 활동"
            @submit="submitDialog(7)"
          >
            <template v-slot:body>
              매일 해야 하는 과제를 완수하면 스크립트에 입력된 보상을 지급하는 컨텐츠. ActivityHandler를 상속받아 업적과 비슷한 프로세스로 처리. 진행했던 내용들은 다음날 모두 초기화 처리.
            </template>
          </my-dialog>
        </v-dialog>
        
        <v-btn
          class="ma-2"
          dark
          @click="showDialog(8)"
        >
          외형 변경권
        </v-btn>
        <v-dialog
          max-width="800"
          v-model="dialogsDataList[8].flag"
        >
          <my-dialog
            header-title="외형 변경권"
            @submit="submitDialog(8)"
          >
            <template v-slot:body>
              캐릭터의 외모를 변경하는 티켓을 소모하여, 외형을 다시 만드는 기능.
            </template>
          </my-dialog>
        </v-dialog>
        
        <v-btn
          class="ma-2"
          dark
          @click="showDialog(9)"
        >
          특수 업적 (도전 과제)
        </v-btn>
        <v-dialog
          max-width="800"
          v-model="dialogsDataList[9].flag"
        >
          <my-dialog
            header-title="특수 업적 (도전 과제)"
            @submit="submitDialog(9)"
          >
            <template v-slot:body>
              특수한 상황에서 조건에 맞는 상황이 되어야, 진행도를 올려주는 컨텐츠. 샌드박스 형 조건 체크 기능 추가 구현 후, 기존 업적 시스템과 결합.
            </template>
          </my-dialog>
        </v-dialog>

      </v-container>
    </v-main>
  </v-app>
</template>

<script>
import MyDialog from './dialog/mydialog'

export default {
  name: 'MyWork',
  components: {
    MyDialog,
  },
  data: () => ({
    dialogFlag: false,
    dialogsDataList :[
      { flag: false },  //  0
      { flag: false },  //  1
      { flag: false },  //  2
      { flag: false },  //  3
      { flag: false },  //  4
      { flag: false },  //  5
      { flag: false },  //  6
      { flag: false },  //  7
      { flag: false },  //  8
      { flag: false },  //  9
      { flag: false },  //  10
      { flag: false },  //  11
      { flag: false },  //  12
      { flag: false },  //  13
      { flag: false },  //  14

      { flag: false },
      { flag: false },
      { flag: false },
      { flag: false },
      { flag: false },
    ]
  }),
  methods: {
    showDialog: function (i) {
      this.dialogsDataList[i].flag = true
    },
    hideDialog: function (i) {
      this.dialogsDataList[i].flag = false
    },
    submitDialog: function (i) {
      this.hideDialog(i)
    },
  }
}
</script>

<!--
<template>
    <v-container>
        <v-dialog>
            <v-template>                
                <v-btn>
                    업적
                </v-btn>
            </v-template>

        </v-dialog>
    </v-container>
</template>

<script>
export default {
    name: 'MyWork',

    data: () => ({

    }),

    methods: {

    },
}
</script>
-->