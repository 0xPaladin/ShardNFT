//localforage
import "../lib/localforage.1.10.0.min.js"
//chance
import "../lib/chance.min.js"

//UI
import UI from "./UI.js"
//UI
import * as ETH from "./eth.js"

//Save db for Indexed DB 
const DB = localforage.createInstance({
  name: "Battle.d20",
})

//Main APP object
let app = {
  DB,
  state : {},
  loadGame () {}
}

ETH.init(app)

// load ui 
UI(app)

