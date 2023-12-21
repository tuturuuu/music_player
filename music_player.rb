    require 'rubygems'
    require 'gosu'
    require 'ruby-progressbar'
    require 'audioinfo'
    require 'tk'

    module ZOrder
    BACKGROUND, PLAYER, UI = *0..2
    end

    class Album
        # NB: you will need to add tracks to the following and the initialize()
            attr_accessor :artist, :name,:tracks, :artWork
            def initialize (artist, name, tracks, artWork)
                # insert lines here
                @artist = artist
                @name = name
                @tracks = tracks
                @artWork = artWork
            end
        end
        
    class Track
        attr_accessor :name, :location
            def initialize (name, location)
            @name = name
            @location = location
        end
    end
        
    class ArtWork
        attr_accessor :bmp, :file
        def initialize (file)
            @bmp = Gosu::Image.new(file)
            @file = file
        end
    end

    # Put your record definitions here

    class MusicPlayerMain < Gosu::Window
        def initialize
            super 1600, 900
            self.caption = "Music Player"
            @albums = readAlbums("albums.txt")
            @song = nil
            @loop = false
            @album_playing = -1
            @current_album = -1
            @track_playing = -1
            @tab = 0
            @song_start_time 
            @song_length
            @progressbar
            @paused = false
        end

        def close
        # Your cleanup code here
        puts 'Window is closing...'
            
        File.open('albums.txt', 'w') do |file|
            file.write(@albums.length.to_s + "\n")
            index = 0 
            while index < (@albums.length)
                file.write(@albums[index].artist + "\n")
                file.write(@albums[index].name + "\n")
                file.write(@albums[index].artWork.file + "\n")
                file.write(@albums[index].tracks.length.to_s + "\n")
                print_tracks(@albums[index].tracks, file)
                index +=1
            end
            
        end
        # Call the original close method to actually close the window
        super
    end

    def print_tracks(tracks, file)
        count = tracks.length() 
        i = 0
        while i < count
            file.write(tracks[i].name + "\n")
            file.write(tracks[i].location + "\n")
            i = i+1
        end
      end

    # Put in your code here to load albums and tracks

    def readAlbums(file_name)
        begin
        music_file = File.new(file_name, "r")
        rescue Errno::ENOENT
            puts "File #{file_name} does not exist."
        rescue Errno::EACCES
            puts "File #{file_name} is not readable."
        else
            albums = Array.new
            albumNum = music_file.gets.to_i
            albumNum.times do
                artist = music_file.gets.chomp
                album_name = music_file.gets.chomp
                art_work = ArtWork.new(music_file.gets.chomp)
                track_num = music_file.gets.to_i
                tracks = read_track(track_num, music_file)
                album = Album.new(artist, album_name, tracks, art_work)
                albums << album
            end
            return albums
        end
        return nil
    end

    def read_track(track_num, music_file)
        tracks = Array.new()
        i = 0
        while i < track_num
            name = music_file.gets.chomp
            location = music_file.gets.chomp
            track = Track.new(name, location)
            tracks << track
            i += 1
        end 
        return tracks
    end


    # Draws the artwork on the screen for all the albums

    def draw_albums()
        index = @tab
        column = 0
        row = 1
        items = 1
        2.times do
            3.times do
                image = @albums[index].artWork.bmp
                image.draw((150 + 300*(column)), 100*row ,1)
                index += 1
                column +=1
                if (index == (@albums.length))
                    return
                end
            end
            row += 3
            column = 0 
        end
    end

    # Takes a track index and an Album and plays the Track from the Album
    def playTrack(album_index, track_index)
        begin
          # Play the selected track
          track_location = @albums[album_index].tracks[track_index].location.chomp
          @song = Gosu::Song.new(track_location)
          @song.play(@loop)
          @track_playing = track_index
          @album_playing = album_index
          @song_start_time = Gosu::milliseconds
          info = AudioInfo.open(track_location)
          @song_length = info.length * 1000 # Convert to milliseconds
          @progressbar = ProgressBar.create(:total => @song_length)
          @paused = false
        rescue StandardError => e
          puts "Error playing track: #{e.message}"
        end
      end
      

    def draw_background
        draw_rect(
            0, 0, 1600, 900, Gosu::Color::WHITE,
            ZOrder::BACKGROUND
        )

        draw_rect(
            0, 700, 1600, 3, Gosu::Color::GRAY,
            ZOrder::BACKGROUND
        )

        draw_rect(
            1170, 440, 1600, 3, Gosu::Color::GRAY,
            ZOrder::BACKGROUND
        )
        draw_rect(
            1170, 0, 3, 700, Gosu::Color::GRAY,
            ZOrder::BACKGROUND
        )

        if((@tab + 6) < @albums.length)
            image = Gosu::Image.new("assets/buttons/right_arrow_v4.png")
            image.draw(1050, 340, 1)
        end

        if(@tab > 0)
            image = Gosu::Image.new("assets/buttons/left_arrow_v4.png")
            image.draw(30, 330, 1)
        end
        if(@song != nil)
            if @song.playing?
                image = Gosu::Image.new("assets/buttons/button_start_v4.png")
                image.draw(750, 750, 1)
            else
                image = Gosu::Image.new("assets/buttons/button_stop_v4.png")
                image.draw(750, 750, 1)
            end
        else
            image = Gosu::Image.new("assets/buttons/button_stop_v3.png")
            image.draw(750, 750, 1)
        end
        if @loop
            image = Gosu::Image.new("assets/buttons/loop_v2.png")
            image.draw(1350, 755, 1)
        else
            image = Gosu::Image.new("assets/buttons/not_loop_v3.png")
            image.draw(1350, 755, 1)
        end
        image = Gosu::Image.new("assets/buttons/add_album_v3.png")
        image.draw(1216, 750, 1) 
        image = Gosu::Image.new("assets/buttons/remove_album_v3.png")
        image.draw(1100, 750, 1)
        image = Gosu::Image.new("assets/buttons/skip_v2.png")
        image.draw(900, 757, 1)
        image = Gosu::Image.new("assets/buttons/prev_v2.png")
        image.draw(615, 765, 1)
        if (@current_album != -1 && @current_album < @albums.length)
            image = Gosu::Image.new("assets/buttons/add_track_v3.png")
            image.draw(1500, 350, 1)
            image = Gosu::Image.new("assets/buttons/remove_track.png")
            image.draw(1425, 347, 1)
        end
    end
      

    def draw_progress_bar
          # Define the dimensions of the progress bar
        if(@progressbar == nil)
            return
        end
        x = 0
        y = 700
        width = 1600
        height = 4

        # Calculate the width of the filled part based on the song's progress
        filled_width = (@progressbar.progress.to_f / @progressbar.total) * width

        # Draw the background of the progress bar
        Gosu.draw_rect(x, y, width, height, Gosu::Color::GRAY)

        # Draw the filled part of the progress bar
        Gosu.draw_rect(x, y, filled_width, height, Gosu::Color::BLACK)
    end
    # Not used? Everything depends on mouse actions.

        def update
            if Gosu.button_down?(Gosu::Button::KbSpace)
                if(@song != nil)
                    if @song.playing?
                        @song.pause
                        @paused = true
                    else
                        @song.play
                        @paused = false
                    end
                end
            end

            if(@progressbar != nil)

                if @paused 
                    return
                end

                if(@loop)
                    current_position = Gosu::milliseconds - @song_start_time
                    # If the song has finished and looped back to the start, reset the progress bar
                    if current_position >= @song_length
                      @song_start_time = Gosu::milliseconds
                      current_position = 0
                    end
                    # Update the progress bar based on the current position
                    @progressbar.progress = current_position
                else
                    if Gosu::milliseconds - @song_start_time < @song_length
                        @progressbar.progress = Gosu::milliseconds - @song_start_time
                    end
                end
            end
        end
    # Draws the album images and the track list for the selected album
        def draw
            draw_albums
            draw_background
            #draw_mouse_pointer_coordinates
            draw_progress_bar

            if(@album_playing < @albums.length)
                if(@albums[@album_playing].tracks != nil)
                    if(@song != nil && @track_playing < @albums[@album_playing].tracks.length)
                        if @song.playing?
                            font = Gosu::Font.new(25)
                            font.draw_text("Playing track: " + @albums[@album_playing].tracks[@track_playing].name , 100, 750, 0, 1, 1, Gosu::Color::BLACK)
                            font.draw_text("From album: " + @albums[@album_playing].name , 100, 800, 0, 1, 1, Gosu::Color::BLACK)
                        else
                            font = Gosu::Font.new(25)
                            font.draw_text("Paused track: " + @albums[@album_playing].tracks[@track_playing].name , 100, 750, 0, 1, 1, Gosu::Color::BLACK)
                            font.draw_text("From album: " + @albums[@album_playing].name , 100, 800, 0, 1, 1, Gosu::Color::BLACK)
                        end
                    end
                end
            end

            if(@current_album >= @albums.length)
                return
            end
            if(@current_album != -1)
                index = 0
                font = Gosu::Font.new(20)
                font.draw_text("Album " + (@current_album + 1).to_s + ": " + @albums[@current_album].name, 1200, 50, 0, 1, 1, Gosu::Color::BLACK)
                if(@albums[@current_album].tracks != nil)
                    while index < @albums[@current_album].tracks.length
                        font = Gosu::Font.new(20)
                        prompt =(index+1).to_s + ". " + @albums[@current_album].tracks[index].name
                        font.draw_text(prompt, 1200, 50 + 50*(index+1), 0, 1, 1, Gosu::Color::BLACK)
                        index += 1
                    end
                end
            end

            if(@current_album != -1)
                font = Gosu::Font.new(20)
                font.draw_text("Album artist: " + @albums[@current_album].artist, 1200, 500, 0, 1, 1, Gosu::Color::BLACK)
                font.draw_text("Album label: " + @albums[@current_album].name, 1200, 550, 0, 1, 1, Gosu::Color::BLACK)
            end
        end

        def needs_cursor?; true; end

        def button_down(id)
            case id
            when Gosu::MsLeft
                handle_click
            end
        end

    end


    def handle_click
        check_album_click
        check_play_track_click
        check_start_stop_click
        check_skip_prev_click
        check_next_prev_tab
        check_loop
        check_add_album
        check_add_track
        check_remove_album
        check_remove_track
    end

    def check_album_click
        index = @tab
        column = 0
        row = 1
        items = 1
        while index < @albums.length
          if mouse_in_area(150 + (300 * column), 150 + (300 * column) + @albums[index].artWork.bmp.width, 100*row, 100*row + @albums[index].artWork.bmp.height)
            @current_album = index
            return
          end
          index += 1
          items += 1
          column +=1
          if items == 4
            row += 3
            items = 0
            column = 0
          end    
        end
      end
      
    def check_play_track_click
        index = 0
        while index < @albums.length
          if mouse_in_area(1200, 1500, 75 + (index) * 50, 75 + (index) * 50 + 50)
            playTrack(@current_album, index)
            return
          end
          index += 1
        end
    end

    def check_start_stop_click
        if mouse_in_area(755, 830, 750, 830)
            if(@song != nil)
                if @song.playing?
                    @song.pause
                    @paused = true
                else
                    @song.play
                    @paused = false
                end
            end
        end
    end

    def check_skip_prev_click
        if(@song == nil)
            return
        end
        if !@song.playing?
            return
        end
        if mouse_in_area(910, 960, 770, 815)
            if((@track_playing + 1) != @albums[@album_playing].tracks.length)
                @track_playing += 1
                playTrack(@album_playing, @track_playing)    
                return
            else
                @track_playing = 0
                playTrack(@album_playing, (@track_playing))
            end
        end
        if mouse_in_area(632, 792, 772, 815)
            if(@track_playing  != 0)
                @track_playing -= 1
                playTrack(@album_playing, @track_playing)    
                return
            else
                @track_playing = (@albums[@album_playing].tracks.length - 1)
                playTrack(@album_playing, @track_playing)
            end
        end
    end

    def check_next_prev_tab
        if((@tab + 6) < @albums.length)
            if mouse_in_area(1070, 1107, 350, 400)
                @tab += 6
            end
        end
        if (@tab > 0)
            if mouse_in_area(48, 82, 342, 400)
                @tab -= 6
            end
        end
    end

    def check_loop
        if mouse_in_area(1365, 1425, 765, 815)
            if @loop 
                @loop = false
            else
                @loop = true
            end
        end
    end

    def check_add_album
        if mouse_in_area(1225, 1288, 760, 820)
            # Create a hidden root window
            root = TkRoot.new {withdraw}
            # Create a new top-level window
            dialog = TkToplevel.new(root)
            # Set the title of the dialog window
            dialog.title "Add album"
            # Set the size of the dialog window
            dialog.geometry "400x300"
            # Add a label to the dialog
            label1 = TkLabel.new(dialog) {
              text "Please enter the album name:"
              pack :padx => "3m", :pady => "3m"
            }
            # Add an entry field to the dialog
            entry1 = TkEntry.new(dialog) {
              pack :padx => "3m", :pady => "3m"
            }
            # Add a second label to the dialog
            label2 = TkLabel.new(dialog) {
              text "Please enter the artist name:"
              pack :padx => "3m", :pady => "3m"
            }
            # Add a second entry field to the dialog
            entry2 = TkEntry.new(dialog) {
              pack :padx => "3m", :pady => "3m"
            }
            # Add a button to the dialog
            album = nil
            button = TkButton.new(dialog) {
              text "OK"
              command proc {
                Tk::messageBox :message => "Please select the location of the artwork."
                art_work_loc = Tk::getOpenFile
                album_name = entry1.value
                artist_name = entry2.value
                # Show a message box with the track name and the album name
                Tk::messageBox :message => "Album name is #{album_name}\n Artwork location is #{art_work_loc}\nArtist name is #{artist_name}"
                art_work = ArtWork.new(art_work_loc.chomp)
                tracks = Array.new
                album = Album.new(artist_name, album_name, tracks, art_work)
                # Exit the Tkinter event loop
                dialog.destroy
              }
              pack :padx => "3m", :pady => "3m"
            }
            # Wait for the user to close the dialog
            dialog.wait_window
            @albums << album
        end
    end

    def check_add_track
        if mouse_in_area(1500, 1550, 352, 390)
            # Create a hidden root window
            root = TkRoot.new {withdraw}
            # Create a new top-level window
            dialog = TkToplevel.new(root)
            # Set the title of the dialog window
            dialog.title "Add track"
            # Set the size of the dialog window
            dialog.geometry "400x300"
            # Add a label to the dialog
            label1 = TkLabel.new(dialog) {
              text "Please enter the track name:"
              pack :padx => "3m", :pady => "3m"
            }
            # Add an entry field to the dialog
            entry1 = TkEntry.new(dialog) {
              pack :padx => "3m", :pady => "3m"
            }
            track = nil
            # Add a button to the dialog
            button = TkButton.new(dialog) {
              text "OK"
              command proc {
                Tk::messageBox :message => "Please select track location."
                track_loc = Tk::getOpenFile
                track_name = entry1.value
                Tk::messageBox :message => "Track name is #{track_name}\n Track location is #{track_loc}\n"
                track = Track.new(track_name, track_loc)
                # Exit the Tkinter event loop
                dialog.destroy
              }
              pack :padx => "3m", :pady => "3m"
            }
            # Wait for the user to close the dialog
            dialog.wait_window
            if(track != nil)
                @albums[@current_album].tracks << track
            end
        end
    end

    def check_remove_album
        if mouse_in_area(1112, 1173, 756, 820)
            # Create a hidden root window
            root = TkRoot.new {withdraw}
            # Create a new top-level window
            dialog = TkToplevel.new(root)
            # Set the title of the dialog window
            dialog.title "Remove album"
            # Set the size of the dialog window
            dialog.geometry "400x300"
            # Add a label to the dialog
            label1 = TkLabel.new(dialog) {
              text "Please enter the album number:"
              pack :padx => "3m", :pady => "3m"
            }
            # Add an entry field to the dialog
            entry1 = TkEntry.new(dialog) {
              pack :padx => "3m", :pady => "3m"
            }
            album_i = -1
            # Add a button to the dialog
            button = TkButton.new(dialog) {
              text "OK"
              command proc {
                album_i = entry1.value.to_i - 1
                Tk::messageBox :message => "Removed album #{album_i + 1}\n"
                # Exit the Tkinter event loop
                dialog.destroy
              }
              pack :padx => "3m", :pady => "3m"
            }
            # Wait for the user to close the dialog
            
            dialog.wait_window
            if(album_i != -1)
                @albums.delete_at(album_i) 
            end
        end
    end

    def check_remove_track
        if mouse_in_area(1430, 1470, 352, 390)
            # Create a hidden root window
            root = TkRoot.new {withdraw}
            # Create a new top-level window
            dialog = TkToplevel.new(root)
            # Set the title of the dialog window
            dialog.title "Remove track"
            # Set the size of the dialog window
            dialog.geometry "400x300"
            # Add a label to the dialog
            label1 = TkLabel.new(dialog) {
              text "Please enter the track number:"
              pack :padx => "3m", :pady => "3m"
            }
            # Add an entry field to the dialog
            entry1 = TkEntry.new(dialog) {
              pack :padx => "3m", :pady => "3m"
            }
            track_i = -1
            # Add a button to the dialog
            button = TkButton.new(dialog) {
              text "OK"
              command proc {
                track_i = entry1.value.to_i - 1
                Tk::messageBox :message => "Removed track #{track_i + 1}\n"
                # Exit the Tkinter event loop
                dialog.destroy
              }
              pack :padx => "3m", :pady => "3m"
            }
            # Wait for the user to close the dialog
            
            dialog.wait_window
            if(track_i != -1)
                @albums[@current_album].tracks.delete_at(track_i) 
            end
        end
    end

    def mouse_in_area(leftX, rightX, topY, bottomY)
        if mouse_x.between?(leftX, rightX) && mouse_y.between?(topY, bottomY)
            return true
        else 
            return false
        end
    end
    
      
    
    # def draw_mouse_pointer_coordinates
    #     font = Gosu::Font.new(20)
    #     font.draw_text("Mouse X: #{mouse_x}, Mouse Y: #{mouse_y}", 10, 10, 0, 1, 1, Gosu::Color::BLACK)
    # end

    # Show is a method that loops through update and draw

    MusicPlayerMain.new.show if __FILE__ == $0