defmodule TyperaceWeb.PlayLive do
  use TyperaceWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div>Render</div>
    """
  end
end
