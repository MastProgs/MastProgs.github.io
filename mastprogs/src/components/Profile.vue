<template>
  <v-container>

    <div>
      <v-row md-gutters>
        <v-col
          cols="6"
          md="4"
          xs="12"
        >
          <v-img
            max-width="500"
            src="../assets/myface2.png">
            
          </v-img>
        </v-col>
        <v-col
          cols="12"
          sm="6"
          md="8"
        >
          <h1>김형준</h1>
          <p>게임 서버 프로그래머</p>
          
          <v-divider></v-divider>
          <br>

          <span>게임을 좋아해서 QA를 시작으로 2013년에 게임업계 발을 들이고 난 이후, 현재는 {{ "2017-08-07" | moment("from", "now", true) }} 년차가 된 서버 프로그래머 입니다. 
          다양한 게임을 장르 구분 없이 많이 좋아하는 편이며, PC 및 콘솔 게임 등 플랫폼 관련 없이 즐기는 것을 좋아합니다. 
          항상 프로그래머로서 성장하기 위해 노력하며 최신 기술인 C++17, C++20 같은 표준에도 관심을 갖고 있습니다. 
          게임 분야 뿐 아니라 AI 및 빅데이터, 클라우드 같은 사회적 이슈 기술에 대해서도 많은 관심이 있습니다. 
          저와 같이 성장해 나갈 수 있는 회사를 관심 깊게 찾고 있습니다.</span>

        </v-col>
      </v-row>
    </div>

    <div>
      <br>
      <v-row md-gutters>

        <v-col>
            <v-img src="../assets/cpp.png" max-width="75" max-height="75"/>
        </v-col>
        <v-col>
            <v-img src="../assets/cpppp.png" max-width="75" max-height="75"/>
        </v-col>
        <v-col>
            <v-img src="../assets/sql.png" max-width="75" max-height="75"/>
        </v-col>
        <v-col>
            <v-img src="../assets/redis.jpg" max-width="75" max-height="75"/>
        </v-col>
        <v-col>
            <v-img src="../assets/js.png" max-width="75" max-height="75"/>
        </v-col>
        <v-col>
            <v-img src="../assets/typescript.png" max-width="75" max-height="75"/>
        </v-col>
        <v-col>
            <v-img src="../assets/logo.png" max-width="75" max-height="75"/>
        </v-col>
        <v-col>
            <v-img src="../assets/python.png" max-width="75" max-height="75"/>
        </v-col>
        <v-col>
            <v-img src="../assets/aws.png" max-width="75" max-height="75"/>
        </v-col>
        <v-col>
            <v-img src="../assets/azure.jpg" max-width="75" max-height="75"/>
        </v-col>
      </v-row>
    </div>

    <div>
      <br>
      <v-divider></v-divider>
      <br>
      <h1>연락처</h1>
      <v-row>
        <v-col cols="12" sm="4">
          <v-text-field label="Phone" value="OIO - 4I4O - O34I" outlined readonly/>
        </v-col>
        <v-col cols="12" sm="4">
          <v-text-field label="Email" value="_for@kakao.com" outlined readonly/>
        </v-col>        
        <v-col cols="12" sm="1">
          <v-btn block fab href="https://github.com/MastProgs" target="_blank">
            <v-img src="../assets/github.png" max-width="50" max-height="50"/>
          </v-btn>
        </v-col>        
        <v-col cols="12" sm="1">
          <v-btn block fab href="https://post.naver.com/my/series/detail.nhn?seriesNo=370283&memberNo=559061" target="_blank">
            <v-img src="../assets/naverpost.png" max-width="50" max-height="50"/>
          </v-btn>
        </v-col>
      </v-row>
    </div>

    <div class="text-center">
      <v-divider></v-divider>
      <br>
      <v-row>
        <v-col cols="12" sm="4">
          <h1>대학교</h1>
          <v-layout align-center justify-center>
            <v-img src="../assets/kpu.png" max-width="200" max-height="100"/>
          </v-layout>
          <p><br>게임공학과 4년제 학사 졸업<br>2015.03.01 ~ 2018.02.09</p>
        </v-col>
        <v-col cols="12" sm="4">
          <h1>대학원</h1>
          <v-layout align-center justify-center>
            <v-img src="../assets/kookmin.png" max-width="200" max-height="100"/>
          </v-layout>
          <p><br>인공지능과 석사 재학<br>2021.03.01 ~ (진행중)</p>
        </v-col>
        <v-col cols="12" sm="4">
          <h1>군력</h1>
          <v-layout align-center justify-center>
            <v-img src="../assets/airforce.png" max-width="200" max-height="100"/>
          </v-layout>
          <p><br>대한민국 공군 병장 만기 전역<br>2010.11.22 ~ 2012.11.23</p>
        </v-col>
      </v-row>
    </div>

    <div>
      <br>
      <v-divider></v-divider>
      <br>
      <h1>가치관</h1>
      <br>
      <h3>항상 성장을 추구하며 앞서가는 프로그래머</h3>
      <v-textarea
        filled
        auto-grow
        readonly
        value="현재 이 순간에도 IT 기술들은 매우 발빠르게 성장하며 앞서나가고 있으며, 너무 방대한 발전 기술들이 쏟아지면서 하나의 지식을 익히기에도 오랜 시간과 열정이 필요하여 많은 학습을 요구하는 시대입니다. 이런 상황에서 늘 열린 자세로 새로운 신기술들을 익히기위해 노력하며, 학습한 여러 기술과 정보들을 실무에 적용하기 위한 노력도 해보고, 관심있어 하시는 분들과 함께 공부한 내용을 공유하기도 합니다. 공부하고 알아갈 수록 부족한 부분이 많다는 것을 깨닫기에, 언제나 겸손한 자세로 지식 뿐만 아니라 다른 여러 인문학적인 요소들도 스스로 채우려 노력합니다."
      />
      <!--
      <p>현재 이 순간에도 IT 기술들은 매우 발빠르게 성장하며 앞서나가고 있으며, 너무 방대한 발전 기술들이 쏟아지면서 하나의 지식을 익히기에도 오랜 시간과 열정이 필요하여 많은 학습을 요구하는 시대입니다. 이런 상황에서 늘 열린 자세로 새로운 신기술들을 익히기위해 노력하며, 학습한 여러 기술과 정보들을 실무에 적용하기 위한 노력도 해보고, 관심있어 하시는 분들과 함께 공부한 내용을 공유하기도 합니다. 공부하고 알아갈 수록 부족한 부분이 많다는 것을 깨닫기에, 언제나 겸손한 자세로 지식 뿐만 아니라 다른 여러 인문학적인 요소들도 스스로 채우려 노력합니다.</p>
      -->

      <h3>격의 없는 커뮤니케이션과 열린 마음</h3>
      <v-textarea
        filled
        auto-grow
        readonly
        value="프로젝트는 혼자 작업하지 않습니다. 기획적인 요청에 있어서 매번 다른 요구가 들어올 수 도 있으며, 동료 프로그래머 분들과 함께 작업하면서 많은 협업을 진행하게 됩니다. 매번 설계와 수정을 반복하면서 다양한 피드백을 받아 내고 유동적으로 움직이는 역할 또한 매우 중요하다는 사실을 알고 있습니다. 저는 언제나 여러 요청들에 대해 긍정적으로 수용할 자세가 되어있고 그 어느 의견이든지 존중하려고 합니다. 이러한 자세가 저 스스로 뿐만 아니라 함께 성장하고 배울 수 있는 환경을 조성하고 조직 전체가 긍정적으로 나아갈 수 있는 방향이라고 생각합니다."
      />
      <!--
      <p>프로젝트는 혼자 작업하지 않습니다. 기획적인 요청에 있어서 매번 다른 요구가 들어올 수 도 있으며, 동료 프로그래머 분들과 함께 작업하면서 많은 협업을 진행하게 됩니다. 매번 설계와 수정을 반복하면서 다양한 피드백을 받아 내고 유동적으로 움직이는 역할 또한 매우 중요하다는 사실을 알고 있습니다. 저는 언제나 여러 요청들에 대해 긍정적으로 수용할 자세가 되어있고 그 어느 의견이든지 존중하려고 합니다. 이러한 자세가 저 스스로 뿐만 아니라 함께 성장하고 배울 수 있는 환경을 조성하고 조직 전체가 긍정적으로 나아갈 수 있는 방향이라고 생각합니다.</p>
      -->
      <h3>믿고 함께 신뢰 할 수 있는 프로그래머</h3>
      <v-textarea
        filled
        auto-grow
        readonly
        value="프로그래밍은 1과 0으로 이루어져있는 논리 연산입니다. 오류가 있다면 차근차근 풀어나가야 하며 이런 순서를 건너뛰고 누군가 마법처럼 해결해 주는 일은 없습니다. 덮어놓고 있는다고 하여 가려질 수 있는 직업도 아닙니다. 오류나 실수가 있다면 발빠르게 인정하고 최대한 신속하게 대응하고 만회하기 위해 노력합니다. 작업에 있어 항상 완벽하다고 보장할 수는 없지만, 적어도 제 작업에 있어서 신뢰할 수 있는 프로그래머로 인정받을 수 있도록 노력을 많이 합니다. 동료로부터 믿음이 있어야 협업을 장애없이 이어 갈 수 있으며, 문제가 발견되었더라도 빠르게 오류를 보완하여 앞으로 나아갈 수 있다는 것을 잘 알고 있습니다."
      />
      <!--
      <p>프로그래밍은 1과 0으로 이루어져있는 논리 연산입니다. 오류가 있다면 차근차근 풀어나가야 하며 이런 순서를 건너뛰고 누군가 마법처럼 해결해 주는 일은 없습니다. 덮어놓고 있는다고 하여 가려질 수 있는 직업도 아닙니다. 오류나 실수가 있다면 발빠르게 인정하고 최대한 신속하게 대응하고 만회하기 위해 노력합니다. 작업에 있어 항상 완벽하다고 보장할 수는 없지만, 적어도 제 작업에 있어서 신뢰할 수 있는 프로그래머로 인정받을 수 있도록 노력을 많이 합니다. 동료로부터 믿음이 있어야 협업을 장애없이 이어 갈 수 있으며, 문제가 발견되었더라도 빠르게 오류를 보완하여 앞으로 나아갈 수 있다는 것을 잘 알고 있습니다.</p>
      -->
    </div>

    <div>
      <v-divider></v-divider>
      <br>
      <h1>마지막 인사말</h1>
      <br>
      <h3>함께 일할 동료 분들 및 프로젝트 방향에 맞는 최적의 가치를 제공하기 위해 최선을 다하겠습니다.</h3>
      <br>
      <span>
        여러 프로젝트 경험과 꾸준한 자기계발을 기반으로, 저에게 요구되는 역할에 대해 최선을 다함으로써 최적의 가치를 제공할 것을 약속 드립니다.
        더 나아가, 유기적인 협력과 확장성 있는 자세를 통해 신뢰할 수 있는 최고의 파트너가 될 수 있도록 노력하겠습니다.
        <br><br>
        끝까지 긴 글을 읽어 주셔서 감사드리며, 지속적인 관심과 지원을 당부드립니다.
        <br><br>
        고맙습니다.
        <v-img src="../assets/sign2.png" max-width="500" max-height="500"/>
      </span>
    </div>

    <br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>

  </v-container>
</template>

<script>
  export default {
    name: 'Profile',

    mounted() {

    },

    data: () => ({
      m_program_list_item: [
        { imgsrc:'../assets/cpp.png', w:'75', h:'75'},
        { imgsrc:'../assets/cpppp.png', w:'75', h:'75'},
        { imgsrc:'../assets/js.png', w:'75', h:'75'},
        { imgsrc:'../assets/logo.png', w:'75', h:'75'},
        { imgsrc:'../assets/python.png', w:'75', h:'75'},
        { imgsrc:'../assets/aws.png', w:'75', h:'75'},
        { imgsrc:'../assets/azure.jpg', w:'75', h:'75'},
      ],
    }),

    methods: {
      isMobile() {
        if(/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)) {
          return true
        } else {
          return false
        }
      }
    },
  }
</script>
