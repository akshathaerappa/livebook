defmodule LivebookWeb.OpenLive.UploadComponent do
  use LivebookWeb, :live_component

  @impl true
  def mount(socket) do
    {:ok,
     socket
     |> assign(:error, false)
     |> allow_upload(:notebook, accept: ~w(.livemd), max_entries: 1)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex-col space-y-5">
      <p class="text-gray-700" id="import-from-file">
        Drag and drop a .livemd file below to import it.
      </p>
      <form
        id="upload-file-form"
        phx-submit="save"
        phx-change="validate"
        phx-drop-target={@uploads.notebook.ref}
        phx-target={@myself}
        class="flex flex-col items-start"
      >
        <.live_file_input
          upload={@uploads.notebook}
          class="hidden"
          aria-labelledby="import-from-file"
        />
        <div
          class="flex flex-col justify-center items-center w-full rounded-xl border-2 border-dashed border-gray-400 h-48"
          phx-hook="Dropzone"
          id="import-file-upload-dropzone"
        >
          <%= if @uploads.notebook.entries == [] do %>
            <span name="placeholder" class="font-medium text-gray-400">Drop your notebook here</span>
          <% else %>
            <div :for={file <- @uploads.notebook.entries} class="flex items-center">
              <span class="font-medium text-gray-400"><%= file.client_name %></span>
              <button
                type="button"
                class="icon-button"
                phx-click="clear-file"
                phx-target={@myself}
                tabindex="-1"
              >
                <.remix_icon icon="close-line" class="text-xl text-gray-300 hover:text-gray-500" />
              </button>
            </div>
          <% end %>
        </div>
        <%= if @error do %>
          <div class="text-red-500 text-sm py-2">
            You can only upload files with .livemd extension.
          </div>
        <% end %>
        <button
          type="submit"
          class="mt-5 button-base button-blue"
          disabled={@uploads.notebook.entries == [] || @error}
        >
          Import
        </button>
      </form>
    </div>
    """
  end

  @impl true
  def handle_event("clear-file", _params, socket) do
    {socket, _entries} = Phoenix.LiveView.Upload.maybe_cancel_uploads(socket)
    {:noreply, assign(socket, error: false)}
  end

  @impl true
  def handle_event("validate", _params, socket) do
    has_error? = Enum.any?(socket.assigns.uploads.notebook.entries, &(not &1.valid?))

    {:noreply, assign(socket, error: has_error?)}
  end

  @impl true
  def handle_event("save", _params, socket) do
    consume_uploaded_entries(socket, :notebook, fn %{path: path}, _entry ->
      content = File.read!(path)

      send(self(), {:import_source, content, []})

      {:ok, :ok}
    end)

    {:noreply, socket}
  end
end
