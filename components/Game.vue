<template>
	<section class="relative bg-lionz-purple" id="game-section">
		<h2 class="mb-2 flex justify-center">
			<!-- TODO: change this to the right title when available -->
			<img
				data-aos="fade-down"
				class="h-16"
				src="@/assets/images/lions-game.png"
				alt="FAQ" />
		</h2>

		<div class="flex justify-center">
			<div class="max-w-2xl">
				<p class="leading-loose text-lionz-yellow mb-5 text-shadow-xl">
					Play the first of many metajungle games and experiences right now,
					right here!
				</p>
			</div>
		</div>

		<div class="flex flex-col items-center mx-auto md:w-[960px]">
			<div class="w-full md:w-[960px] md:h-[600px] relative block">
				<canvas
					ref="unity"
					class="
						w-full
						md:w-[960px] md:h-[600px]
						text-lionz-yellow
						bg-[url(/Build/webgl.jpg)] bg-cover bg-center
					"></canvas>
				<div
					v-if="showLoadingBar"
					class="
						absolute
						top-[50%]
						left-[50%]
						transform
						translate-x-[-50%] translate-y-[-50%]
						w-[300px]
					">
					<div class="w-full">
						<div
							id="unity-progress-bar-full"
							class="h-8 bg-lionz-accent"
							:style="{ width: progressBarPercent }"></div>
					</div>
				</div>
			</div>

			<!-- SMALL MODE ONLY -->
			<div class="text-lionz-yellow md:hidden p-4 rounded-md block sm:hidden">
				Play on Desktop - Coming soon to Google Play Store
			</div>
			<div class="w-full block">
				<!-- hidden sm:block"> -->
				<img
					src="~/assets/images/fullscreen-button.png"
					class="ml-auto h-16 w-16 cursor-pointer"
					@click="setFullscreen" />
			</div>
		</div>

		<div class="w-full flex items-center justify-center py-12">
			<label
				for="score-modal"
				class="
					btn
					modal-button
					bg-orange-400
					hover:bg-orange-300
					text-lionz-accent
				"
				>Check Scores</label
			>

			<!-- Put this part before </body> tag -->
			<input type="checkbox" id="score-modal" class="modal-toggle" />
			<label for="score-modal" class="modal cursor-pointer">
				<label
					class="
						modal-box
						max-w-fit
						relative
						bg-lionz-light-brown
						text-lionz-accent
					"
					for="">
					<div
						class="
							tabs
							flex
							items-center
							justify-center
							!border-lionz-light-brown
						">
						<button
							v-for="(game, index) in games"
							class="tab tab-xs tab-bordered text-lionz-accent"
							:class="{
								'tab-active': game.isSelected,
								'!border-lionz-accent': game.isSelected,
							}"
							@click="selectGame(index)">
							{{ game.name }}
						</button>
					</div>
					<div class="overflow-x-auto">
						<table class="table table-compact w-full">
							<thead>
								<tr>
									<th class="bg-transparent">Name</th>
									<th class="bg-transparent">Score</th>
								</tr>
							</thead>
							<tbody>
								<tr v-for="(score, index) in selectedGame.scores">
									<td
										:class="{
											'bg-transparent': index > 2,
											'bg-amber-700': index === 0,
											'bg-amber-600': index === 1,
											'bg-amber-500': index === 2,
										}">
										{{ score.name }}
									</td>
									<td
										:class="{
											'bg-transparent': index > 2,
											'bg-amber-700': index === 0,
											'bg-amber-600': index === 1,
											'bg-amber-500': index === 2,
										}">
										{{ score.score }}
									</td>
								</tr>
							</tbody>
						</table>
					</div>
				</label>
			</label>
		</div>
	</section>
</template>

<script>
export default {
	data() {
		return {
			showLoadingBar: true,
			canvasWidth: 960,
			canvasHeight: 600,
			progressBarPercent: '0%',
			unityInstance: {},
			games: [],
		}
	},
	mounted() {
		// Shows a temporary message banner/ribbon for a few seconds, or
		// a permanent error message on top of the canvas if type=='error'.
		// If type=='warning', a yellow highlight color is used.
		// Modify or remove this function to customize the visually presented
		// way that non-critical warnings and error messages are presented to the
		// user.

		var config = {
			dataUrl: '/Build/webgl.data.gz',
			frameworkUrl: '/Build/webgl.framework.js.gz',
			codeUrl: '/Build/webgl.wasm.gz',
			streamingAssetsUrl: '/StreamingAssets',
			companyName: 'Fueled on Bacon',
			productName: 'fob-cyberlionz-runner',
			productVersion: '0.1.4',
			showBanner: this.unityShowBanner,
			showLoadingBar: true,
		}

		// By default Unity keeps WebGL canvas render target size matched with
		// the DOM size of the canvas element (scaled by window.devicePixelRatio)
		// Set this to false if you want to decouple this synchronization from
		// happening inside the engine, and you would instead like to size up
		// the canvas DOM size and WebGL render target sizes yourself.
		// config.matchWebGLToCanvasSize = false;

		if (/iPhone|iPad|iPod|Android/i.test(navigator.userAgent)) {
			// Mobile device style: fill the whole browser client area with the game canvas:
			// To lower canvas resolution on mobile devices to gain some
			// performance, uncomment the following line:
			// config.devicePixelRatio = 1
		} else {
			// Desktop style: Render the game canvas in a window that can be maximized to fullscreen:
		}

		window.addEventListener('load', () => {
			// run after everything is in-place
			try {
				window
					.createUnityInstance(this.$refs.unity, config, (progress) => {
						if (progress > 0.98) {
							this.showLoadingBar = false
						}
						this.progressBarPercent = 100 * progress + '%'
					})
					.then((unityInstance) => {
						this.showLoadingBar = false
						this.unityInstance = unityInstance
					})
					.catch((message) => {
						alert(message)
					})
			} catch (err) {
				console.log(err)
			}
		})

		this.fetchScores()
	},
	methods: {
		setFullscreen() {
			this.unityInstance.SetFullscreen(1)
		},

		async fetchScores() {
			const responseData = await this.$axios.$get(
				'https://enigmafactorygames.com/cyberlionz/scores/TopScoresAllJSON.php?unique=1&latest=0'
			)
			console.log(responseData)

			const scoreBoard = responseData

			if (scoreBoard.games) {
				this.games = scoreBoard.games.map((game, index) => {
					return {
						...game,
						isSelected: index === 0,
					}
				})
			}
		},

		selectGame(index) {
			this.games = this.games.map((game, gameIndex) => {
				return {
					...game,
					isSelected: gameIndex === index,
				}
			})
		},
	},
	computed: {
		selectedGame() {
			if (this.games.length > 0) {
				return this.games.filter((game) => game.isSelected).pop()
			}
			return {
				scores: [],
			}
		},
	},
}
</script>
