defmodule TyperaceWeb.CarLive do
  use TyperaceWeb, :live_view
  import TyperaceWeb.GameComponents

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
      <div class="relative w-full h-[200px]">
        <.road />
        <.car
          id="123"
          color="red"
          x={0}
          y={20}
          />
        <.car
          id="456"
          color="blue"
          x={0}
          y={65}
        />
      </div>
    """
  end
end
