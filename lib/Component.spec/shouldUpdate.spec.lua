return function()
	local createElement = require(script.Parent.Parent.createElement)
	local createReconciler = require(script.Parent.Parent.createReconciler)
	local createSpy = require(script.Parent.Parent.createSpy)
	local NoopRenderer = require(script.Parent.Parent.NoopRenderer)
	local Type = require(script.Parent.Parent.Type)
	local deepEqual = require(script.Parent.Parent.deepEqual)

	local Component = require(script.Parent.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	it("should be invoked when props update", function()
		local MyComponent = Component:extend("MyComponent")

		local capturedProps
		local capturedState
		local shouldUpdateSpy = createSpy(function(self)
			capturedProps = self.props
			capturedState = self.state

			return true
		end)

		MyComponent.shouldUpdate = shouldUpdateSpy.value

		function MyComponent:render()
			return nil
		end

		local initialProps = {
			a = 5,
		}
		local initialElement = createElement(MyComponent, initialProps)
		local hostParent = nil
		local key = "Test"

		local node = noopReconciler.mountNode(initialElement, hostParent, key)

		expect(shouldUpdateSpy.callCount).to.equal(0)

		local newProps = {
			a = 6,
			b = 2,
		}
		local newElement = createElement(MyComponent, newProps)
		noopReconciler.updateNode(node, newElement)

		expect(shouldUpdateSpy.callCount).to.equal(1)

		local values = shouldUpdateSpy:captureValues("self", "newProps", "newState")

		expect(Type.of(values.self)).to.equal(Type.StatefulComponentInstance)

		assert(deepEqual(values.newProps, newProps))
		assert(deepEqual(capturedProps, initialProps))

		expect(values.newState).to.equal(capturedState)
		assert(deepEqual(capturedState, {}))
	end)

	it("should be invoked when state is updated", function()
		local MyComponent = Component:extend("MyComponent")

		local initialState = {
			a = 1,
		}

		local setState
		local initState
		function MyComponent:init()
			setState = function(...)
				return self:setState(...)
			end

			self:setState(initialState)

			initState = self.state
		end

		local capturedProps
		local capturedState
		local shouldUpdateSpy = createSpy(function(self)
			capturedProps = self.props
			capturedState = self.state

			return true
		end)

		MyComponent.shouldUpdate = shouldUpdateSpy.value

		function MyComponent:render()
			return nil
		end

		local initialElement = createElement(MyComponent)
		local hostParent = nil
		local key = "Test"

		noopReconciler.mountNode(initialElement, hostParent, key)

		expect(shouldUpdateSpy.callCount).to.equal(0)

		local newState = {
			a = 2,
			b = 3,
		}

		setState(newState)

		expect(shouldUpdateSpy.callCount).to.equal(1)

		local values = shouldUpdateSpy:captureValues("self", "newProps", "newState")

		expect(Type.of(values.self)).to.equal(Type.StatefulComponentInstance)

		assert(values.newProps == capturedProps)
		assert(deepEqual(capturedProps, {}))

		assert(deepEqual(capturedState, initialState))
		expect(capturedState).to.equal(initState)
		assert(deepEqual(values.newState, newState))
	end)

	it("should not abort an update when returning true", function()
		local MyComponent = Component:extend("MyComponent")

		function MyComponent:shouldUpdate()
			return true
		end

		local renderSpy = createSpy()

		MyComponent.render = renderSpy.value

		local initialElement = createElement(MyComponent)
		local hostParent = nil
		local key = "Test"

		local node = noopReconciler.mountNode(initialElement, hostParent, key)

		expect(renderSpy.callCount).to.equal(1)

		local newElement = createElement(MyComponent)
		noopReconciler.updateNode(node, newElement)

		expect(renderSpy.callCount).to.equal(2)
	end)

	it("should abort an update when retuning false", function()
		local MyComponent = Component:extend("MyComponent")

		function MyComponent:shouldUpdate()
			return false
		end

		local renderSpy = createSpy()

		MyComponent.render = renderSpy.value

		local initialElement = createElement(MyComponent)
		local hostParent = nil
		local key = "Test"

		local node = noopReconciler.mountNode(initialElement, hostParent, key)

		expect(renderSpy.callCount).to.equal(1)

		local newElement = createElement(MyComponent)
		noopReconciler.updateNode(node, newElement)

		expect(renderSpy.callCount).to.equal(1)
	end)
end