<template>
  <v-app>
    <v-main>
      <v-container>
        <v-btn
          dark
          @click="showDialog"
        >
          show dialog!
        </v-btn>
        <v-dialog
          max-width="500"
          v-model="dialogFlag"
        >
          <roro-dialog
            @hide="hideDialog"
            @submit="submitDialog"
          />
        </v-dialog>
      </v-container>
    </v-main>
  </v-app>
</template>

<script>
import RoroDialog from './dialog/mydialog'

export default {
  name: 'MyWork',
  components: {
    RoroDialog,
  },
  data: () => ({
    dialogFlag: false,
  }),
  methods: {
    showDialog() {
      this.dialogFlag = true
    },
    hideDialog() {
      this.dialogFlag = false
    },
    submitDialog() {
      console.log('submit 완료!')
      this.hideDialog()
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