//Preact
import {h, Component, render} from 'https://unpkg.com/preact?module';
import htm from 'https://unpkg.com/htm?module';
// Initialize htm with Preact
const html = htm.bind(h);

const UI = (app)=>{
  //for use in other modules 
  app.UI = {
    h,
    Component,
    render,
    html
  }

  const ShardSVG = (shard)=>{
    let props = ["Climate", "Rainfall", "Terrain", "Feature", "Size"]

    return html`
    <svg xmlns="http://www.w3.org/2000/svg" height="250" width="250" preserveAspectRatio="xMinYMin meet" viewBox="0 0 150 150" class="pa1">
      <style>.base { fill: white; font-family: serif; font-size: 14px; }</style>
      <rect width="100%" height="100%" fill="black"></rect>
      <text x="10" y="20" class="base">Id: ${shard.id}</text>
      ${shard.d.map((d,i)=>html`<text x="10" y=${40 + i * 20} class="base">${props[i]}: ${d}</text>`)}
    </svg>
    `
  }

  class App extends Component {
    constructor() {
      super();
      this.state = {
        show: "newScape",
        address: "",
        netId: 0,
        balance: 0,
        cost: 0,
        totalSupply: 0,
        balanceOf: 0,
        shards: {},
        tx: [0, ""],
        time: Date.now(),
      };
    }

    // Lifecycle: Called whenever our component is created
    componentDidMount() {
      app.UI.main = this
      // update time every second
      this.timer = setInterval(()=>{
        this.setState({
          time: Date.now()
        })
      }
      , 500);

      //connect 
      app.eth.connect()
    }

    // Lifecycle: Called just before our component will be destroyed
    componentWillUnmount() {
      // stop when not renderable
      clearInterval(this.timer);
    }

    setShow = (show)=>this.setState({
      show
    });

    connectWallet = ()=>{
      app.eth.connect()
    }

    connectButton = ()=>{
      let {address} = this.state
      return address != "" ? "" : html`<a class="link dim ph3 pv2 mb2 dib white bg-blue br2" href="#0" onClick=${()=>this.connectWallet()}>Connect Wallet</a>`
    }

    claim = async()=>{
      let {balance, cost} = this.state
      if (balance < cost)
        return

      let c = app.contracts.Shard
      let value = app.eth.parseUnits(String(cost))

      //call claim 
      let tx = await c.claim({
        value
      })
      console.log(tx)

      this.setState({
        tx: [Date.now(),tx.hash]
      })
    }

    render(props, {show, netId, cost, address, balance, shards, tx, time}) {

      let shortAddress = address != "" ? address.slice(0, 5) + "..." + address.slice(-3) : ""

      return html`
      <div>
        <div class="ma2 flex items-center justify-between">
          <h1 class="ma0">Shards</h1>
          <div>${shortAddress}${this.connectButton()}</div>
        </div>
        <div class="mh5">
          <p>A <span class="f4 b i">Shard</span> is an island floating in the cosmos. A simple NFT completely generated on chain. Inspired by Treasure Project and Rarity.</p>
          <p>Claim your own, or many. No max supply. Cost will always be less than $1.</p>
          <p>Only available on the following networks: EVMOS</p>
        </div>
        <div class="flex justify-center">
          ${cost == 0 ? "" : html`<a class="f3 tc link dim white bg-blue br2 w-100 mw7 ph3 pv2" href="#0" onClick=${()=>this.claim()}>Claim Shard <span class="f5 ph2">(${cost})</span></a>`}
        </div>
        <div class="mv2 flex justify-center">${time - tx[0] < 15000 ? "tx submitted: " + tx[1] : ""}</div>
        <div class="flex justify-center pa1">
          ${Object.values(shards).map(ShardSVG)}
        </div>
        <div class="z-0 fixed bottom-1 right-1 w-20"></div>
      </div>
      `
    }
  }

  render(html`<${App}/>`, document.body);
}

export {UI as default}
