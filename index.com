<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Music Search</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <link href="https://fonts.googleapis.com/css2?family=Noto+Sans+KR:wght@400;500;700&display=swap" rel="stylesheet">
    <style>
        body {
            font-family: 'Noto Sans KR', sans-serif;
            background-color: #F3E8FF; /* Light lavender background */
        }
        .card {
            background-color: white;
            border-radius: 20px;
            box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
        }
        /* .player background is now set by JS */
        
        /* Custom scrollbar for search results */
        #searchResults::-webkit-scrollbar {
            width: 8px;
        }
        #searchResults::-webkit-scrollbar-track {
            background: #f1f1f1;
            border-radius: 10px;
        }
        #searchResults::-webkit-scrollbar-thumb {
            background: #C4B5FD; /* Lighter purple */
            border-radius: 10px;
        }
        #searchResults::-webkit-scrollbar-thumb:hover {
            background: #A78BFA; /* Darker purple on hover */
        }
        .settings-content {
            max-height: 0;
            overflow: hidden;
            transition: max-height 0.5s ease-in-out;
        }
        .settings-content.open {
            max-height: 500px; /* Adjust as needed */
        }
        
        /* Layout Styles */
        .player.layout-horizontal {
            flex-direction: row;
            align-items: center;
            width: 100%;
        }
        .player.layout-horizontal .album-art {
            width: 5rem; /* 80px */
            height: 5rem;
        }
        .player.layout-horizontal .info-section {
            margin-left: 1rem;
            text-align: left;
        }
        .player.layout-horizontal .info-section .flex {
            justify-content: flex-start;
        }
        .player.layout-horizontal .controls-section {
            flex-direction: row;
            align-items: center;
        }

        .player.layout-vertical {
            flex-direction: column;
            align-items: center;
            width: 288px; /* w-72 */
        }
        .player.layout-vertical .album-art {
            width: 10rem; /* 160px */
            height: 10rem;
        }
        .player.layout-vertical .info-section {
            margin-left: 0;
            margin-top: 1rem;
            text-align: center;
            width: 100%; /* Ensure the container has a defined width */
            padding: 0 1rem; /* Add horizontal padding */
        }
        .player.layout-vertical .info-section .flex {
            justify-content: center;
        }
        .player.layout-vertical .controls-section {
            flex-direction: column;
            margin-top: 1rem;
            gap: 0.5rem; /* space-y-2 */
        }
        .player.layout-vertical .controls-section canvas {
            margin-left: 0;
        }
    </style>
</head>
<body class="flex items-center justify-center min-h-screen">
    <div class="w-full max-w-3xl mx-auto p-4">
        <header class="text-center mb-6">
            <h1 id="mainTitle" class="text-2xl font-bold text-purple-800">Music search</h1>
        </header>

        <!-- Settings Section -->
        <div class="card mb-6 overflow-hidden">
            <div id="settingsToggle" class="flex justify-between items-center p-4 bg-purple-600 text-white cursor-pointer">
                <h2 class="font-bold">설정 열기/닫기</h2>
                <svg id="settingsArrow" class="w-6 h-6 transform transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7"></path></svg>
            </div>
            <div id="settingsContent" class="settings-content p-6 space-y-6">
                <div>
                    <label for="displayNameInput" class="block text-sm font-medium text-gray-700">표시 채널명</label>
                    <div class="mt-1 flex space-x-2">
                        <input type="text" id="displayNameInput" placeholder="채널명을 입력하세요" class="flex-grow px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:outline-none focus:ring-purple-500 focus:border-purple-500">
                        <button id="applyDisplayName" class="px-4 py-2 bg-purple-500 text-white rounded-md hover:bg-purple-600">적용</button>
                    </div>
                </div>
                <div>
                    <label for="imageUpload" class="block text-sm font-medium text-gray-700">커버 이미지 업로드</label>
                    <div class="mt-2 flex space-x-2">
                         <label class="cursor-pointer px-4 py-2 bg-purple-500 text-white rounded-md hover:bg-purple-600">
                            <span>이미지 업로드</span>
                            <input type="file" id="imageUpload" class="hidden" accept="image/*">
                         </label>
                         <button id="revertCover" class="px-4 py-2 bg-gray-200 text-gray-700 rounded-md hover:bg-gray-300">원래 썸네일</button>
                    </div>
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700">카드 색상</label>
                    <div class="mt-2 flex items-center space-x-2">
                        <div class="flex flex-col items-center">
                            <span class="text-xs text-gray-500 mb-1">기본 색상</span>
                            <input type="color" id="primaryColor" value="#A855F7" class="w-10 h-10 p-1 border-0 rounded-md cursor-pointer">
                        </div>
                        <div class="flex flex-col items-center">
                            <span class="text-xs text-gray-500 mb-1">보조 색상</span>
                            <input type="color" id="secondaryColor" value="#7C3AED" class="w-10 h-10 p-1 border-0 rounded-md cursor-pointer">
                        </div>
                        <button id="applyColors" class="self-end px-4 py-2 bg-purple-500 text-white rounded-md hover:bg-purple-600">색상 적용</button>
                        <button id="resetColors" class="self-end px-4 py-2 bg-gray-200 text-gray-700 rounded-md hover:bg-gray-300">기본 색상</button>
                    </div>
                </div>
                <div>
                    <label class="block text-sm font-medium text-gray-700">카드 레이아웃</label>
                    <div class="mt-2 flex space-x-2">
                        <button id="layoutHorizontalBtn" class="px-4 py-2 bg-purple-500 text-white rounded-md hover:bg-purple-600 transition-colors">가로형</button>
                        <button id="layoutVerticalBtn" class="px-4 py-2 bg-gray-200 text-gray-700 rounded-md hover:bg-gray-300 transition-colors">세로형</button>
                    </div>
                </div>
            </div>
        </div>

        <main class="card p-6">
            <!-- Search Section -->
            <div class="flex items-center space-x-2">
                <input type="text" id="searchInput" placeholder="아티스트나 곡명을 검색하세요..." class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-500 transition">
                <button id="searchButton" class="bg-purple-600 text-white px-5 py-2 rounded-lg hover:bg-purple-700 focus:outline-none focus:ring-2 focus:ring-purple-500 focus:ring-opacity-50 transition-transform transform active:scale-95">
                    검색
                </button>
            </div>
             <!-- Loading and Results Section -->
            <div id="status" class="text-center text-gray-500 mt-4 h-6"></div>
            <div id="searchResults" class="mt-4 max-h-64 overflow-y-auto space-y-2">
                <!-- Search results will be injected here -->
            </div>
        </main>

        <!-- Player Section (Now called "Card") -->
        <footer class="mt-8 flex justify-center">
            <div id="player" class="player flex p-4 rounded-2xl shadow-lg text-white transition-all duration-500 ease-in-out transform layout-horizontal">
                <img id="albumArt" src="https://placehold.co/80x80/6d28d9/ffffff?text=Album" alt="Album Art" class="album-art rounded-lg shadow-md flex-shrink-0 transition-all">
                <div class="flex-grow min-w-0 info-section">
                    <h2 id="trackTitleWrapper" class="font-bold text-lg flex min-w-0 items-baseline">
                        <span id="trackTitle" class="truncate">노래 제목</span>
                        <span id="trackArtist" class="ml-2 flex-shrink-0"></span>
                    </h2>
                    <div class="flex items-center text-sm opacity-80">
                        <span class="mr-2">SING 🎤</span>
                        <p id="artistName">채널명</p>
                    </div>
                </div>
                <div class="controls-section flex items-center">
                    <div class="flex items-center space-x-2 text-2xl">
                        <!-- Static decorative icons -->
                        <svg class="w-8 h-8" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M4 4a1 1 0 00-1 1v10a1 1 0 001 1h1a1 1 0 001-1V5a1 1 0 00-1-1H4z"></path><path d="M15.25 14.5a1 1 0 01-1.5.866l-6-4.5a1 1 0 010-1.732l6-4.5a1 1 0 011.5.866v8.5z"></path></svg>
                        <svg class="w-8 h-8" fill="currentColor" viewBox="0 0 20 20"><path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z" clip-rule="evenodd"></path></svg>
                        <svg class="w-8 h-8" fill="currentColor" viewBox="0 0 20 20" xmlns="http://www.w3.org/2000/svg"><path d="M15 4a1 1 0 00-1 1v10a1 1 0 001 1h1a1 1 0 001-1V5a1 1 0 00-1-1h-1z"></path><path d="M4.75 14.5a1 1 0 001.5.866l6-4.5a1 1 0 000-1.732l-6-4.5a1 1 0 00-1.5.866v8.5z"></path></svg>
                    </div>
                    <canvas id="waveformCanvas" width="120" height="40" class="ml-4"></canvas>
                </div>
            </div>
        </footer>

    </div>

    <script>
        document.addEventListener('DOMContentLoaded', () => {
            // --- CONFIGURATION ---
            const clientId = '13ada5c13a834887b16d181b5730a8b3';
            const clientSecret = 'e29f437d6c3d46509926b78b0fd885fb';
            // --- END CONFIGURATION ---

            const searchInput = document.getElementById('searchInput');
            const searchButton = document.getElementById('searchButton');
            const searchResultsContainer = document.getElementById('searchResults');
            const statusDiv = document.getElementById('status');
            
            const playerDiv = document.getElementById('player');
            const albumArtImg = document.getElementById('albumArt');
            const trackTitleSpan = document.getElementById('trackTitle');
            const trackArtistSpan = document.getElementById('trackArtist');
            const artistNameP = document.getElementById('artistName');

            // Settings Elements
            const settingsToggle = document.getElementById('settingsToggle');
            const settingsContent = document.getElementById('settingsContent');
            const settingsArrow = document.getElementById('settingsArrow');
            const displayNameInput = document.getElementById('displayNameInput');
            const applyDisplayName = document.getElementById('applyDisplayName');
            const imageUpload = document.getElementById('imageUpload');
            const revertCover = document.getElementById('revertCover');
            const primaryColor = document.getElementById('primaryColor');
            const secondaryColor = document.getElementById('secondaryColor');
            const applyColors = document.getElementById('applyColors');
            const resetColors = document.getElementById('resetColors');
            const layoutHorizontalBtn = document.getElementById('layoutHorizontalBtn');
            const layoutVerticalBtn = document.getElementById('layoutVerticalBtn');
            const waveformCanvas = document.getElementById('waveformCanvas');


            let accessToken = null;
            let originalAlbumArtUrl = ''; // To store original spotify URL
            let isCustomCoverActive = false; // To track if a custom image is uploaded

            // --- Gradient Update Function ---
            function updatePlayerGradient(isReset = false) {
                const color1 = isReset ? '#A855F7' : primaryColor.value;
                const color2 = isReset ? '#7C3AED' : secondaryColor.value;
                const direction = playerDiv.classList.contains('layout-vertical') ? '180deg' : '90deg';
                playerDiv.style.background = `linear-gradient(${direction}, ${color1}, ${color2})`;
            }

            // --- Event Listeners for Settings ---

            settingsToggle.addEventListener('click', () => {
                settingsContent.classList.toggle('open');
                settingsArrow.classList.toggle('rotate-180');
            });
            
            applyDisplayName.addEventListener('click', () => {
                const newChannelName = displayNameInput.value.trim();
                if(newChannelName) {
                    artistNameP.textContent = newChannelName;
                }
            });

            imageUpload.addEventListener('change', (event) => {
                const file = event.target.files[0];
                if (file) {
                    const reader = new FileReader();
                    reader.onload = (e) => {
                        albumArtImg.src = e.target.result;
                        isCustomCoverActive = true;
                    };
                    reader.readAsDataURL(file);
                }
            });
            
            revertCover.addEventListener('click', () => {
                if(originalAlbumArtUrl) {
                    albumArtImg.src = originalAlbumArtUrl;
                }
                isCustomCoverActive = false;
            });
            
            applyColors.addEventListener('click', () => updatePlayerGradient());

            resetColors.addEventListener('click', () => {
                primaryColor.value = '#A855F7';
                secondaryColor.value = '#7C3AED';
                updatePlayerGradient(true);
            });
            
            layoutHorizontalBtn.addEventListener('click', () => {
                playerDiv.classList.remove('layout-vertical');
                playerDiv.classList.add('layout-horizontal');
                updatePlayerGradient();
                
                // Style buttons
                layoutHorizontalBtn.classList.add('bg-purple-500', 'text-white');
                layoutHorizontalBtn.classList.remove('bg-gray-200', 'text-gray-700');
                layoutVerticalBtn.classList.add('bg-gray-200', 'text-gray-700');
                layoutVerticalBtn.classList.remove('bg-purple-500', 'text-white');
            });

            layoutVerticalBtn.addEventListener('click', () => {
                playerDiv.classList.remove('layout-horizontal');
                playerDiv.classList.add('layout-vertical');
                updatePlayerGradient();
                
                // Style buttons
                layoutVerticalBtn.classList.add('bg-purple-500', 'text-white');
                layoutVerticalBtn.classList.remove('bg-gray-200', 'text-gray-700');
                layoutHorizontalBtn.classList.add('bg-gray-200', 'text-gray-700');
                layoutHorizontalBtn.classList.remove('bg-purple-500', 'text-white');
            });

            // --- Decorative Waveform Animation ---
            const canvasCtx = waveformCanvas.getContext('2d');
            let frame = 0;

            function drawDecorativeWaveform() {
                frame++;
                const width = waveformCanvas.width;
                const height = waveformCanvas.height;
                const barCount = 15;
                const barWidth = width / barCount / 2;

                canvasCtx.clearRect(0, 0, width, height);

                for (let i = 0; i < barCount; i++) {
                    const barHeight = (Math.sin((frame + i * 5) * 0.1) + 1) * (height / 2.5) + (height * 0.1);
                    const x = i * (barWidth * 2 + 3);
                    const y = height - barHeight;

                    canvasCtx.fillStyle = 'rgba(255, 255, 255, 0.8)';
                    canvasCtx.fillRect(x, y, barWidth, barHeight);
                }

                requestAnimationFrame(drawDecorativeWaveform);
            }
            drawDecorativeWaveform();


            // --- Spotify API Functions ---

            const getAccessToken = async () => {
                if (clientId === 'YOUR_SPOTIFY_CLIENT_ID' || clientSecret === 'YOUR_SPOTIFY_CLIENT_SECRET') {
                    console.error("Spotify Client ID/Secret is not set. Please update the script.");
                    statusDiv.textContent = "Spotify API 키를 설정해주세요.";
                    return null;
                }
                try {
                    const response = await fetch('https://accounts.spotify.com/api/token', {
                        method: 'POST',
                        headers: {
                            'Content-Type': 'application/x-www-form-urlencoded',
                            'Authorization': 'Basic ' + btoa(clientId + ':' + clientSecret)
                        },
                        body: 'grant_type=client_credentials'
                    });

                    if (!response.ok) throw new Error(`Spotify token error: ${response.statusText}`);
                    
                    const data = await response.json();
                    return data.access_token;
                } catch (error) {
                    console.error('Error getting access token:', error);
                    statusDiv.textContent = "API 토큰 인증에 실패했습니다.";
                    return null;
                }
            };

            const searchTracks = async (query) => {
                if (!accessToken) {
                    statusDiv.textContent = "인증 중...";
                    accessToken = await getAccessToken();
                    if(!accessToken) return;
                }

                statusDiv.textContent = "검색 중...";
                searchResultsContainer.innerHTML = '';

                try {
                    const response = await fetch(`https://api.spotify.com/v1/search?q=${encodeURIComponent(query)}&type=track&limit=10`, {
                        headers: { 'Authorization': `Bearer ${accessToken}` }
                    });

                    if (!response.ok) {
                        if(response.status === 401) {
                             accessToken = await getAccessToken();
                             if(accessToken) searchTracks(query);
                        } else {
                            throw new Error(`Spotify API error: ${response.statusText}`);
                        }
                        return;
                    }

                    const data = await response.json();
                    displayResults(data.tracks.items);
                } catch (error) {
                    console.error('Error searching tracks:', error);
                    statusDiv.textContent = "검색 중 오류가 발생했습니다.";
                }
            };
            
            const displayResults = (tracks) => {
                if (tracks.length === 0) {
                    statusDiv.textContent = '검색 결과가 없습니다.';
                    return;
                }
                statusDiv.textContent = '';

                tracks.forEach(track => {
                    const trackDiv = document.createElement('div');
                    trackDiv.className = 'flex items-center p-2 rounded-lg cursor-pointer hover:bg-gray-100 transition';
                    
                    const albumImage = track.album.images[2] ? track.album.images[2].url : 'https://placehold.co/64x64/f3e8ff/6d28d9?text=?';
                    const artistNames = track.artists.map(artist => artist.name).join(', ');

                    trackDiv.innerHTML = `
                        <img src="${albumImage}" alt="${track.album.name}" class="w-12 h-12 rounded">
                        <div class="ml-3 min-w-0">
                            <p class="font-semibold text-gray-800 truncate">${track.name}</p>
                            <p class="text-sm text-gray-500 truncate">${artistNames}</p>
                        </div>
                    `;
                    
                    trackDiv.addEventListener('click', () => updatePlayerUI(track));
                    searchResultsContainer.appendChild(trackDiv);
                });
            };

            const updatePlayerUI = (track) => {
                const imageUrl = track.album.images[1] ? track.album.images[1].url : 'https://placehold.co/80x80/6d28d9/ffffff?text=Album';
                const artistNames = track.artists.map(artist => artist.name).join(', ');

                originalAlbumArtUrl = imageUrl;
                imageUpload.value = null;

                if (!isCustomCoverActive) {
                    albumArtImg.src = imageUrl;
                }
                
                trackTitleSpan.textContent = track.name;
                trackArtistSpan.textContent = `- ${artistNames}`;
            };

            // --- Initial Setup & Event Listeners for Search ---
            updatePlayerGradient(true); // Set initial gradient

            const performSearch = () => {
                 const query = searchInput.value.trim();
                if (query) searchTracks(query);
            };
            
            searchButton.addEventListener('click', performSearch);
            searchInput.addEventListener('keyup', (event) => {
                if (event.key === 'Enter') performSearch();
            });

        });
    </script>
</body>
</html>
