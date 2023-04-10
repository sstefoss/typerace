defmodule TyperaceWeb.PageLive do
  use TyperaceWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="flex items-center h-screen">
        <div class="mx-auto text-center justify-center self-center">
          <h1 class="font-bold text-center text-6xl text-white">Welcome to TypeRace!</h1>
          <div class="flex justify-center items-center w-full m-auto mt-20">
            <a
              class="block text-center w-full rounded text-3xl font-medium hover:font-bold text-white hover:text-white focus:outline-none focus:ring"
              href="/create"
            >
              Create Game
            </a>
            <a
              class="block text-center w-full rounded text-3xl font-medium hover:font-bold text-white hover:text-white focus:outline-none focus:ring"
              href="/join"
            >
              Join existing
            </a>
          </div>
        </div>
      </div>
    """
  end
end
