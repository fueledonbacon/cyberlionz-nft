<template>
	<div class="w-full carousel rounded-box relative" ref="carousel">
		<div
			v-for="(item, index) in imageList"
			:id="`carousel_item_${index}`"
			class="carousel-item w-full">
			<img :src="item.src" :alt="item.alt" />

			<div
				v-if="haveNextPrevButtons"
				class="absolute w-full h-full flex justify-between items-center px-1">
				<button
					type="button"
					class="
						btn btn-circle
						border-0
						text-lionz-accent text-lg
						bg-lionz-brown
						hover:bg-lionz-brown
						opacity-60
						hover:opacity-100
					"
					@click="browseCarousel(index, 'previous')">
					❮
				</button>
				<button
					type="button"
					class="
						btn btn-circle
						border-0
						text-lionz-accent text-lg
						bg-lionz-brown
						hover:bg-lionz-brown
						opacity-60
						hover:opacity-100
					"
					@click="browseCarousel(index, 'next')">
					❯
				</button>
			</div>
		</div>
	</div>
</template>

<script>
export default {
	props: {
		items: {
			type: Array,
			required: true,
		},

		haveNextPrevButtons: {
			type: Boolean,
			default: true,
		},

		// automatically change slides every X milliseconds
		changeSlideTimeout: {
			type: Number,
			default: 0,
		},
	},

	data() {
		return {
			currentImageIndex: 0,
			timer: null,
		}
	},

	methods: {
		browseCarousel(currentIndex, direction) {
			let newIndex = currentIndex

			if (direction === 'next') {
				newIndex++
			}
			if (direction === 'previous') {
				newIndex--
			}

			if (newIndex < 0) {
				newIndex = this.imageList.length - 1
			}
			if (newIndex >= this.imageList.length) {
				newIndex = 0
			}

			this.currentImageIndex = newIndex

			const carouselElement = this.$refs.carousel
			const targetElementToScroll = carouselElement.querySelector(
				`#carousel_item_${newIndex}`
			)

			carouselElement.scroll({
				left: targetElementToScroll.offsetLeft,
				behaviour: 'smooth',
			})
		},
	},

	computed: {
		imageList() {
			return this.items.map((item) => {
				const { alt } = item
				return {
					...item,
					alt: alt || 'Carousel Item',
				}
			})
		},
	},

	mounted() {
		const timerFunction = () => {
			this.browseCarousel(this.currentImageIndex, 'next')
		}

		if (this.changeSlideTimeout > 0) {
			// reset timer if user clicks anywhere on carousel
			const carouselElement = this.$refs.carousel
			carouselElement.addEventListener('mousedown', () => {
				if (this.timer) {
					clearInterval(this.timer)
					this.timer = setInterval(timerFunction, this.changeSlideTimeout)
				}
			})

			// set auto change slide timer
			this.timer = setInterval(timerFunction, this.changeSlideTimeout)
		}
	},
}
</script>
