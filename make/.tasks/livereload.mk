# Include this file into your makefile to bring in the following targets:
#
# - livereload-start 						- Start the LiveReload server
# - livereload-stop 						- Stops the LiveReload server
# - livereload 									- Alias to the start target
# - reload 											- Watchable target
#
# Start the livereload server by running `make livereload` and run the
# reload target with watch by running `watch make reload`

livereload-start:
	@echo ... Starting server, running in background ...
	@echo ... Run: "make lr-stop" to stop the server ...
	@which tiny-lr
	@tiny-lr  &

# Alias livereload to the start target
lr: livereload-start

lr-stop:
	curl --ipv4 http://localhost:35729/kill

.PHONY: lr livereload-start lr-stop
