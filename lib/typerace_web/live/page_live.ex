defmodule TyperaceWeb.PageLive do
  use TyperaceWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>
        <h1 class="font-bold font-roboto_mono text-center text-6xl text-white">Welcome to TypeRace</h1>
        <div class="flex flex-col justify-center items-center w-[300px] m-auto mt-10">
          <a
            class="block text-center w-full rounded border border-indigo-600 bg-indigo-600 px-12 py-3 text-sm font-medium text-white hover:bg-transparent hover:text-indigo-600 focus:outline-none focus:ring active:text-indigo-500"
            href="/create"
          >
            Create
          </a>
          <a
            class="block mt-4 text-center w-full rounded border border-indigo-600 px-12 py-3 text-sm font-medium text-indigo-600 hover:bg-indigo-600 hover:text-white focus:outline-none focus:ring active:bg-indigo-500"
            href="/join"
          >
            Join existing
          </a>
        </div>
      </div>
    """
  end
end
