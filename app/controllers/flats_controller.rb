class FlatsController < ApplicationController

  def index
    @flats = policy_scope(Flat).order(created_at: :desc)

    if params[:query].present?
      @query = params[:query]
      @flats = @flats.where("name iLike :query OR location iLike :query OR description iLike :query", query: "%#{params[:query]}%")
    else
      @flats = @flats.all
    end

    if params[:capacity].present?
      @query = params[:capacity].to_i
      @flats = @flats.where("capacity >= :query", query: @query)
    end

    if params[:price_per_night].present?
      @query = params[:price_per_night].to_i
      @flats = @flats.where("price_per_night <= :query", query: @query)
    end

    @markers = @flats.geocoded.map do |flat|
      {
        lat: flat.latitude,
        lng: flat.longitude,
        info_window: render_to_string(partial: "info_window", locals: { flat: flat })
      }
    end
  end

  def new
    @flat = Flat.new
  end

  def create
    @flat = Flat.new(flat_params)
    @flat.user = current_user
    if @flat.save
      redirect_to flats_path
    else
      render :new
    end
  end

  def show
    @flat = Flat.find(params[:id])
    @booking = Booking.new
    @markers = [{
      lat: @flat.latitude,
      lng: @flat.longitude,
      info_window: render_to_string(partial: "info_window", locals: { flat: @flat })
    }]
  end

  def edit
    @flat = Flat.find(params[:id])
  end

  def update
    @flat = Flat.find(params[:id])
    if params[:flat][:photos].present?
      params[:flat][:photos].each do |photo|
        @flat.photos.attach(photo)
      end
    end
    @flat.update(update_params)
    redirect_to flat_path(@flat)
  end

  def destroy
    @flat = Flat.find(params[:id])
    authorize @flat
    @flat.destroy
    redirect_to dashboard_path
  end

  private

  def flat_params
    params.require(:flat).permit(:name, :location, :description, :price_per_night, :capacity, photos: [])
  end

  def update_params
    params.require(:flat).permit(:name, :location, :description, :price_per_night, :capacity)
  end
end
