import * as THREE from 'three'

import vertexShader from '../glsl/vertexShader.glsl'
import fragmentShader from '../glsl/fragmentShader.glsl'

const speed = 0.005 // amount incremented by on each frame
const entry_duration = 1256 // duration of entry animation in ms

let start_t = 0 // shader animation start time

const $canvas = document.getElementById('spores')

const loader = new THREE.TextureLoader()
const image = loader.load('https://storage.googleapis.com/us-static-assets/us-sat-texture.jpg', start);

const $hero = document.getElementById('hero')

const uniforms = { // uniform variables passed to our fragment shader
	u_image: {
		value: image
	},
	u_time: {
		type: 'float',
		value: Math.random() * (Math.random() * 12)
	},
	u_itensity: {
		type: 'float',
		value: 0.01
	},
	u_mouse_c: { // center of our mouse in three.js coords
		type: 'vec2',
		value: new THREE.Vector2(10, 10)
	},
	u_exclusion_c: { // center of our exclusion zone
		type: 'vec2',
		value: new THREE.Vector2(0, 0)
	},
	u_exclusion_s: { // diameter of our exclusion as a ratio of screen width
		type: 'float',
		value: 0.2
	},
	u_res: {
		type: 'vec2',
		value: new THREE.Vector2(window.innerWidth, window.innerHeight)
	}
}

const renderer = new THREE.WebGLRenderer({
	canvas: $canvas,
	alpha: true
})
renderer.setPixelRatio(window.devicePixelRatio)

const scene = new THREE.Scene()

const camera = new THREE.OrthographicCamera(
	window.innerWidth / - 2,
	window.innerWidth / 2,
	window.innerHeight / 2,
	window.innerHeight / - 2,
	1,
	1000
)
camera.position.set(0, 0, 1)

const geometry = new THREE.PlaneBufferGeometry(1, 1, 1, 1)
const material = new THREE.ShaderMaterial({
	uniforms: uniforms,
	vertexShader: vertexShader,
	fragmentShader: fragmentShader,
	defines: {
		dPR: window.devicePixelRatio.toFixed(1)
	}
})

const mesh = new THREE.Mesh(geometry, material)
mesh.scale.set(window.innerWidth, window.innerHeight, 1)

scene.add(mesh)

window.addEventListener('resize', scale, false)
window.addEventListener('mousemove', onMouseMove)

function ease(progress, power = 2) {
  return 1 - (1 - progress) ** power;
}

function scale() {
	uniforms.u_res.x = window.innerWidth
	uniforms.u_res.y = window.innerHeight

	uniforms.u_exclusion_c.value.x = (($hero.offsetLeft + $hero.offsetWidth / 2) / window.innerWidth) * 2 - 1
	uniforms.u_exclusion_c.value.y = -(($hero.offsetTop + $hero.offsetHeight / 2) / window.innerHeight) * 2 + 1

	uniforms.u_exclusion_s.value = ($hero.offsetWidth / window.innerWidth)

	renderer.setSize(window.innerWidth, window.innerHeight)
}

function onMouseMove(ev) {
	uniforms.u_mouse_c.value.x = (ev.clientX / window.innerWidth) * 2 - 1
	uniforms.u_mouse_c.value.y = -(ev.clientY / window.innerHeight) * 2 + 1
}

function start() {
	scale()

	start_t = performance.now()

	$canvas.style.visibility = "visible"

	render(start_t)
}

function render(current_t) {
	if (renderer == undefined) return

	if (uniforms.u_itensity.value < 1) { // animate the shader intensity from 0 to 1 on start
		const elapsed_t = current_t - start_t
		const progress = Math.min(elapsed_t / entry_duration, 1)
		
		uniforms.u_itensity.value = ease(progress)
	}

	requestAnimationFrame(render)

	uniforms.u_time.value += speed

	renderer.render(scene, camera)
}