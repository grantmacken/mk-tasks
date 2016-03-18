# Include this file into your makefile to bring in the following targets:
#
# - lr 						- Start the LiveReload server
# - lr-stop 						- Stops the LiveReload server

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
