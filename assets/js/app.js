// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

// Define hooks
const Hooks = {}

// Hook for handling scroll to top
Hooks.ScrollHandler = {
  mounted() {
    this.handleEvent("scroll_to_top", ({ id }) => {
      const element = document.getElementById(id);
      if (element) {
        element.scrollIntoView({ behavior: "smooth", block: "start" });
      }
    });
  }
}

// ContainerWidth hook for measuring container width
Hooks.ContainerWidth = {
  mounted() {
    this.updateContainerWidth();
    // Add resize listener for responsiveness
    window.addEventListener('resize', this.handleResize.bind(this));
  },
  destroyed() {
    // Clean up resize listener
    window.removeEventListener('resize', this.handleResize.bind(this));
  },
  handleResize() {
    // Debounce the resize event
    clearTimeout(this.resizeTimer);
    this.resizeTimer = setTimeout(() => this.updateContainerWidth(), 250);
  },
  updateContainerWidth() {
    // Get the container width and push to the server
    const width = this.el.clientWidth;
    if (width > 0) {
      this.pushEvent("update_container_width", { width });
    }
  }
}

// VegaLite hook for rendering charts
Hooks.VegaLite = {
  mounted() {
    this.renderChart();
    // Add resize listener for responsiveness
    window.addEventListener('resize', this.handleResize.bind(this));
  },
  updated() {
    this.renderChart();
  },
  destroyed() {
    // Clean up resize listener
    window.removeEventListener('resize', this.handleResize.bind(this));
  },
  handleResize() {
    // Debounce the resize event
    clearTimeout(this.resizeTimer);
    this.resizeTimer = setTimeout(() => this.renderChart(), 250);
  },
  renderChart() {
    try {
      const spec = JSON.parse(this.el.dataset.spec);
      console.log("Rendering chart with spec:", spec);
      
      // We need to load vegaEmbed from a CDN since we're not using npm
      if (window.vegaEmbed) {
        window.vegaEmbed(this.el, spec, {
          actions: false,
          renderer: 'svg',
          width: 'container'
        }).catch(error => {
          console.error("Error rendering chart:", error);
        });
      } else {
        console.error("vegaEmbed is not available. Make sure to include the Vega-Lite library.");
      }
    } catch (error) {
      console.error("Error parsing chart spec:", error);
    }
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
